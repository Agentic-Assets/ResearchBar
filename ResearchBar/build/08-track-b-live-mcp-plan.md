# 08. Track B live MCP plan

This guide wires the native client to Corbis after the backend contract exists.
It covers JSON-RPC, request validation, error mapping, smoke tests, defensive
redaction, and credit-safe refresh.

## Goal

Add a small Corbis MCP client over `URLSession` or the existing
`ProviderHTTPClient` transport. The client calls one aggregate tool,
`get_research_pulse`, and maps every server result into the fixture-tested
menu states from [`06`](06-track-b-fixture-pulse-plan.md).

## Live unlock gate

Live mode is blocked until Corbis Phase 0 proves:

1. `get_research_pulse` appears in `tools/list`.
2. `tools/call` accepts empty arguments.
3. The payload is ORCID anchored.
4. Trend fields are null with `citationHistoryStatus: "not_yet_tracked"` in v0.
5. No internal ids, backend names, or source fields appear in the payload.
6. The call charges exactly 0.5 credits once.
7. The server does not add the per-user pulse to a user-blind cache.

The smoke commands live in [`02-mcp-contract-get-research-pulse.md`](02-mcp-contract-get-research-pulse.md).

## Files to add

| Path | Purpose |
|---|---|
| `Sources/CodexBarCore/ResearchBar/CorbisMCPClient.swift` | JSON-RPC request and response client. |
| `Sources/CodexBarCore/ResearchBar/CorbisMCPEnvelope.swift` | Codable JSON-RPC envelope, result, and error types. |
| `Sources/CodexBarCore/ResearchBar/CorbisMCPError.swift` | Auth, credit, rate-limit, server, decode, semantic, and redaction errors. |
| `Sources/CodexBar/ResearchBar/ResearchPulseRefreshCoordinator.swift` | Menu-open and manual refresh orchestration. |
| `Tests/CodexBarTests/CorbisMCPClientTests.swift` | Mocked HTTP request and response coverage. |
| `Tests/CodexBarTests/ResearchPulseRefreshCoordinatorTests.swift` | Credit-safe refresh behavior and retry suppression. |

## Transport

Prefer the existing `ProviderHTTPTransport` seam from
`Sources/CodexBarCore/ProviderHTTPClient.swift` for testability. The request:

| Field | Value |
|---|---|
| Method | `POST` |
| URL | Configured Corbis MCP base plus `/api/mcp/universal` |
| Headers | `Authorization: Bearer <token>`, `Content-Type: application/json` |
| JSON-RPC method | `tools/call` |
| Params | `{ "name": "get_research_pulse", "arguments": {} }` |

Do not use a Swift MCP SDK in v0. The direct JSON-RPC shape is small and keeps
the dependency surface low.

## Error mapping

| Server or client result | Native state |
|---|---|
| 401 or invalid token envelope | `invalidCredential` |
| 402 or credit error | `creditLimited` |
| 429 | `safeError` with rate-limit wording and no retry loop |
| 500 or malformed JSON-RPC | `safeError` |
| Decode failure | `safeError` |
| Redaction failure | `safeError`, never render raw payload |
| Semantic trend mismatch | `safeError` |
| Success with fresh pulse | Loaded state from [`06`](06-track-b-fixture-pulse-plan.md) |

Never include the bearer token, raw payload, internal ids, or backend source
names in error text.

## Refresh policy

| Trigger | Rule |
|---|---|
| Menu opens | Use fresh cache. If stale, show cache and allow one refresh. |
| Manual refresh | Always available when connected, but coalesce repeated clicks. |
| App launch | Do not spend credits in v0. |
| Background timer | Off in v0. |
| Token validation | Use `tools/list` sparingly and cache the validation result. |
| Credit-limited state | No automatic refresh loops. |

The refresh coordinator should own in-flight tasks so opening and closing the
menu does not spawn duplicate calls.

## Client attribution

Do not invent an attribution scheme in Swift. If Corbis adds a supported
header, for example `X-Corbis-Client: researchbar-macos`, document it here and
send it from `CorbisMCPClient`. Until then, keep the request minimal.

## Captured smoke payload

After Phase 0 is live in a dev or preview environment, archive a redacted clean
payload under:

```text
ResearchBar/build/fixtures/research-pulse-v0-clean.example.json
```

Do not commit bearer tokens, account identifiers that should remain private, or
private profile links.

## Test checklist

1. Request body encodes `tools/call`, `get_research_pulse`, and `{}` arguments.
2. Authorization header is present in the request.
3. Authorization token is absent from thrown errors.
4. JSON-RPC error envelopes map to native states.
5. 401 maps to invalid credential.
6. Credit errors map to credit-limited state.
7. Successful response decodes into `ResearchPulse`.
8. Leak-like successful response is rejected before rendering.
9. Repeated manual refresh coalesces to one in-flight request.
10. Menu-open refresh does not run when the cache is fresh.

## Verification

Focused:

```bash
swift test --filter CorbisMCPClient
swift test --filter ResearchPulseRefreshCoordinator
```

Live smoke after Corbis Phase 0:

```bash
BASE="http://localhost:3000"
curl -s -X POST "$BASE/api/mcp/universal" \
  -H "Authorization: Bearer $CORBIS_MCP_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"get_research_pulse","arguments":{}}}' \
  | tee /tmp/research-pulse.json

rg -i 'openalex|semantic scholar|ssrn|backend|sourceId|authorId|openalexId' /tmp/research-pulse.json
```

The final `rg` must return no matches.

## Done when

- Live client code exists behind the Phase 0 gate.
- Mocked tests cover request shape, auth, errors, redaction, and coalescing.
- Refresh behavior protects free-tier credits.
- A clean captured payload exists only after Corbis smoke passes.
