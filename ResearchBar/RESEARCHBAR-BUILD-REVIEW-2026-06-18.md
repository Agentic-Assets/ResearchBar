---
title: ResearchBar build review
doc_type: audit
status: live
as_of: 2026-06-18
owner: Codex
related:
  - BUILD.md
  - OPEN-ISSUES.md
  - build/02-mcp-contract-get-research-pulse.md
---

# ResearchBar build review, 2026-06-18

## Short answer

The ResearchBar plan is good, but the codebase is not a ResearchBar app yet. It is still CodexBar with a ResearchBar documentation layer. That is fine for this stage. The next useful move is not a global rename or a full product panel. It is a narrow backend-first slice:

1. Corbis ships `get_research_pulse` v0.
2. ResearchBar adds a dedicated `ResearchPulse` model and fixture renderer.
3. ResearchBar swaps fixtures for live MCP only after redaction, ORCID, billing, and freshness are proven.

## What the current repo really is

The actual app code lives under `Sources/CodexBar` and `Sources/CodexBarCore`. The package is still named `CodexBar`, and the implementation is a macOS menu bar usage monitor for AI providers. The docs under `ResearchBar/ResearchBar/` are product and build planning, not shipped functionality.

Useful inherited pieces:

| Existing surface | Why it matters |
|---|---|
| `Sources/CodexBar/CodexbarApp.swift` | Main app entry and menu bar lifecycle. |
| `Sources/CodexBar/StatusItemController.swift` | Status item and menu rendering control point. |
| `Sources/CodexBar/MenuDescriptor.swift` | Descriptor-driven menu rows, useful for a pulse panel. |
| `Sources/CodexBar/SettingsStore.swift` | Existing settings patterns. |
| `Sources/CodexBar/PreferencesProvidersPane.swift` | Provider settings and auth UI reference. |
| `Sources/CodexBar/ProviderRegistry.swift` | Provider registration and display patterns. |
| `Sources/CodexBarCore/ProviderHTTPClient.swift` | Reusable HTTP client patterns. |
| `Sources/CodexBarCore/Providers/ProviderDescriptor.swift` | Provider metadata conventions. |
| `Tests/CodexBarTests` | Place for model, service, cache, and renderer tests. |

Missing today:

| Missing item | Build implication |
|---|---|
| No `Corbis`, `ORCID`, `ResearchPulse`, or `get_research_pulse` code under `Sources` | Track B must add a real client layer. |
| No Corbis MCP JSON-RPC client | Add a small URLSession client before UI work. |
| No account-keyed response cache for pulse payloads | Build before polling. |
| No first-run Corbis identity confirm UI | Stub until Corbis ORCID-first confirm exists. |
| No ResearchBar product naming in package or bundle ids | Defer broad rename until pulse path works. |
| No GRDB dependency in `Package.swift` | Treat GRDB as a deliberate dependency decision, not assumed infrastructure. |

## Build rules for the next contributor

1. **Do not compute research intelligence in Swift.** Swift calls Corbis and renders.
2. **Do not make `UsageSnapshot` carry citation semantics.** Create `ResearchPulse`.
3. **Do not poll in the background until account-keyed caching exists.**
4. **Do not show trend zeros when the server returned null.** Use `citationHistoryStatus`.
5. **Do not show raw backend names or ids.** Test for them even if the backend should redact.
6. **Do not globally rename CodexBar to ResearchBar first.** Working pulse beats cosmetic churn.
7. **Do not add GRDB, a Swift MCP SDK, or a new updater pipeline without sign-off.**

## Recommended Track B file plan

The names below are suggestions. Keep them close to existing package structure.

| Step | Suggested files | Tests |
|---|---|---|
| Pulse model | `Sources/CodexBarCore/ResearchBar/ResearchPulse.swift` | Decode linked, unlinked, null-trend, tracked-trend, low-confidence, stale fixtures. |
| MCP envelope | `Sources/CodexBarCore/ResearchBar/CorbisMCPClient.swift` | JSON-RPC request and response decoding, auth header, error envelopes. |
| Credential storage | `Sources/CodexBar/ResearchBar/CorbisCredentialStore.swift` | Stubbed Keychain tests or protocol tests only. |
| Cache | `Sources/CodexBarCore/ResearchBar/ResearchPulseCache.swift` | Account scoping, `staleAfter`, `etag`, manual invalidation. |
| Menu view model | `Sources/CodexBar/ResearchBar/ResearchPulseMenuModel.swift` | No fake zero trend, no raw ids, correct stale and low-confidence states. |
| Renderer | Existing menu descriptor path plus `Sources/CodexBar/ResearchBar/ResearchPulseMenuFactory.swift` | Snapshot-style descriptor tests. |
| Settings | Existing preferences path plus `Sources/CodexBar/ResearchBar/CorbisSettingsView.swift` | Validate empty token, connected, error, and unlink states. |

## v0 menu states

The v0 panel should support these states before any live launch:

| State | Required display behavior |
|---|---|
| No Corbis credential | Show connect action. No polling. |
| Credential invalid | Show reconnect action. No repeated retry loop. |
| No ORCID confirmed | Show identity confirmation action. No internal ids. |
| Pulse loaded, trend not tracked | Show static citations and a "tracking will begin" state. No sparkline. |
| Pulse loaded, low confidence | Show consolidated values with a confidence notice. No backend names. |
| Stale cache | Show cached values with last fetched time and refresh action. |
| Credit limited | Show credits remaining and avoid automatic refresh loops. |
| Live tracked trend | Draw trend only when all trend fields are non-null and status is `tracked`. |

## Track A dependency

ResearchBar is blocked on Corbis Phase 0. The client can build fixtures and UI, but it should not present live data until the Corbis smoke test proves:

1. `get_research_pulse` appears in `tools/list`.
2. `tools/call` accepts no arguments and resolves caller identity from bearer auth.
3. The response contains ORCID, display name, affiliation, plan, credits, citation totals, h-index, paper count, profile links, freshness metadata, and structured low-confidence flags.
4. Trend fields are null in v0 with `citationHistoryStatus: "not_yet_tracked"`.
5. The payload contains no `openalex`, backend names, internal author ids, or source ids.
6. The call charges 0.5 credits once.
7. The response is not added to a server-side user-blind cache.

## What to defer

| Deferred item | Why |
|---|---|
| Global package rename | It touches packaging, Sparkle, bundle ids, release automation, docs, and tests before the product path is proven. |
| `get_new_work_radar` UI | It needs session-aware server logic and fail-closed ZDR behavior. |
| Data freshness panel | It is Phase 1 after pulse and citation snapshots. |
| Linked repo merge | It needs Corbis repo associations first. Local git can be added later. |
| Agent launcher | It is the moat, but it should come after a working daily pulse. |
| Conference deadlines | It needs curated data ownership and founder commitment. |
| Scholar or SSRN vanity metrics | ToS and vendor posture need sign-off before commercial use. |

## Verification path

During fixture work:

```bash
cd /Users/caymanseagraves/Documents/GitHub/agentic-assets/ResearchBar
swift build
swift test --filter ResearchPulse
```

Before any broad claim that the app is healthy:

```bash
make test
make check
```

Only after live Corbis Phase 0:

```bash
BASE="http://localhost:3000"
curl -s -X POST "$BASE/api/mcp/universal" \
  -H "Authorization: Bearer $CORBIS_MCP_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"get_research_pulse","arguments":{}}}' \
  | tee /tmp/research-pulse.json

rg -i 'openalex|semantic scholar|ssrn|backend|sourceId|authorId|openalexId' /tmp/research-pulse.json
```

The `rg` command should return no matches.

## Builder bottom line

Treat this fork as a good chassis, not as an almost-finished app. Keep the first slice modest: Corbis auth, ORCID identity, one pulse payload, one panel, careful cache, and no fabricated trends. That will answer the real product question faster than a broad rename or a many-panel prototype.
