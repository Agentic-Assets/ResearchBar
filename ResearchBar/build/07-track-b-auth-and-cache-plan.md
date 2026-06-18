# 07. Track B auth and cache plan

This guide adds the local state ResearchBar needs before live MCP calls:
Corbis credential storage, account identity, cache partitioning, freshness
rules, and the GRDB decision point.

## Goal

Build credential and cache seams that keep Corbis account data siloed. The
client may still run from fixtures, but every future live pulse must have a
safe place to store credentials and account-scoped cached payloads.

## Gate

Do not read real Keychain items during automated tests. Follow the root
`AGENTS.md` rule: use protocols, stubs, test stores, and `KeychainNoUIQuery`
patterns. Do not add GRDB without explicit sign-off.

## Files to add

| Path | Purpose |
|---|---|
| `Sources/CodexBar/ResearchBar/CorbisCredentialStore.swift` | Keychain-backed token storage plus protocol for tests. |
| `Sources/CodexBarCore/ResearchBar/CorbisAccountIdentity.swift` | Stable account key fields used for cache partitioning. |
| `Sources/CodexBarCore/ResearchBar/ResearchPulseCache.swift` | Cache protocol, cache key, freshness decision, invalidation. |
| `Sources/CodexBarCore/ResearchBar/FileResearchPulseCache.swift` | Optional v0 file-backed cache if persistent cache is needed before GRDB. |
| `Sources/CodexBar/ResearchBar/CorbisConnectionState.swift` | App-side connection state used by menu and settings. |
| `Tests/CodexBarTests/CorbisCredentialStoreTests.swift` | Protocol and no-UI query coverage. |
| `Tests/CodexBarTests/ResearchPulseCacheTests.swift` | Account scoping, freshness, invalidation, and token-change behavior. |
| `Tests/CodexBarTests/TestResearchBarStores.swift` | Test doubles for credential and cache stores. |

## Credential storage

Use a small protocol so tests never touch production Keychain:

```swift
protocol CorbisCredentialStoring: Sendable {
    func loadCredential() async throws -> CorbisCredential?
    func saveCredential(_ credential: CorbisCredential) async throws
    func deleteCredential() async throws
}
```

`CorbisCredential` should include:

| Field | Rule |
|---|---|
| `token` | Stored only in Keychain, never logged, never copied into error text. |
| `accountID` | Stable Corbis account identity when known. |
| `displayEmail` | Optional display-only account label. |
| `createdAt` | Used for diagnostics only. |
| `lastValidatedAt` | Used to avoid repeated validation loops. |

Private beta can use a pasted personal MCP token. Public launch auth is a
separate decision covered in [`08-track-b-live-mcp-plan.md`](08-track-b-live-mcp-plan.md).

## Cache key

Every cached pulse must be keyed by:

```text
corbisAccountID + toolName + payloadVersion
```

For v0:

| Key part | Value |
|---|---|
| `corbisAccountID` | From verified token response or persisted credential identity. |
| `toolName` | `get_research_pulse`. |
| `payloadVersion` | `v0`. |

If the account identity is unknown, the cache may store only an anonymous
pre-validation entry scoped to the credential fingerprint. It must be cleared
after successful validation maps the token to an account.

## Cache value

Store:

| Field | Purpose |
|---|---|
| `rawJSON` | Re-decode when schema changes. |
| `decodedPulse` | Fast display path. |
| `etag` | Future conditional refresh support. |
| `fetchedAt` | Display and freshness. |
| `staleAfter` | Server cadence. |
| `schemaVersion` | Decode compatibility. |
| `accountID` | Redundant guard against cross-account reads. |

## Freshness rules

| Scenario | Behavior |
|---|---|
| Fresh cache exists | Serve without network call. |
| Stale cache exists and menu opens | Show stale cache immediately, then expose refresh. |
| User manually refreshes | Allow one in-flight refresh per account and tool. |
| Token changes | Clear visible state and invalidate or repartition cache. |
| Account switches | Never display previous account pulse under the new account. |
| Credits exhausted | Do not auto-refresh. Keep safe cache visible if present. |

## GRDB decision

Do not add GRDB in this slice unless Cayman explicitly approves it. The first
implementation should define `ResearchPulseCaching` and can use:

| Option | Use when |
|---|---|
| In-memory cache | Fixture and model work. |
| File-backed JSON cache | Private beta needs persistence and no query complexity. |
| GRDB cache | Multiple payload types, ETag history, or local repo state make SQLite worth the dependency. |

If GRDB is approved later, the protocol should let builders swap
`FileResearchPulseCache` for `GRDBResearchPulseCache` without changing menu or
network code.

## Test checklist

1. Saving a credential never logs the token.
2. Loading a credential respects the no-UI Keychain query policy.
3. Cache lookup for account A never returns account B data.
4. Token change invalidates visible pulse state.
5. Fresh cache skips network refresh.
6. Stale cache is labeled stale and keeps manual refresh available.
7. Credit-limited state disables automatic refresh.
8. Cache serialization preserves `etag`, `fetchedAt`, and `staleAfter`.

## Verification

Focused:

```bash
swift test --filter CorbisCredential
swift test --filter ResearchPulseCache
```

Before handoff:

```bash
swift build
make test
make check
```

## Done when

- Credential storage has a protocol and a Keychain implementation.
- Tests avoid real Keychain prompts.
- Cache keys include Corbis account identity.
- Cache freshness obeys server `staleAfter`.
- GRDB is documented as a decision, not silently added.
