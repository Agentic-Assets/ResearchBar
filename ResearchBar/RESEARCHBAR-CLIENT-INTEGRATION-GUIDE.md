---
title: ResearchBar client integration guide (Track B coding agent)
doc_type: guide
status: live
as_of: 2026-06-27
owner: docs-maintainer
related:
  - docs/researchbar-evaluation/README.md
  - docs/researchbar-evaluation/08-get-research-pulse-v0-spec.md
  - docs/researchbar-evaluation/09-deep-dive-review-and-next-actions.md
  - docs/researchbar-evaluation/build-guides/05-researchbar-native-client-plan.md
  - lib/mcp/tools/output-schemas.ts
  - lib/mcp/auth.ts
  - app/api/mcp/universal/route.ts
---

# ResearchBar client integration guide

> **Audience:** the coding agent (and humans) working in the **`Agentic-Assets/ResearchBar`** repo (the native macOS client, "Track B"). This is the single onboarding document for building ResearchBar against the live Corbis MCP backend. Everything here is verified against `agentic-assets-app` source at the `file:line` anchors shown; when this guide and memory disagree, the code wins, and you should re-verify against the cited file.

This repo-local guide is the ResearchBar client copy of the Corbis backend contract. The backend contract is authored in `agentic-assets-app/docs/researchbar-evaluation/`, and this copy should be refreshed from backend source when the MCP contract changes. Treat the cited backend code as the source of truth for the wire contract.

---

## 0. The 60-second mental model

- **Two repos, one contract.** Corbis (`agentic-assets-app`, this repo) is a Next.js app that exposes a **Model Context Protocol (MCP)** backend over HTTP. ResearchBar is a separate native macOS menu-bar app that is an **MCP client**. ResearchBar never touches the Corbis database, never calls OpenAlex/Semantic Scholar/SSRN directly, and never holds Corbis secrets. It speaks JSON-RPC to one HTTP endpoint with a bearer token.
- **v0 is one tool.** The entire v0 product is rendering **`get_research_pulse`** (a per-user research snapshot) in a menu. A second read-only tool, **`get_data_freshness`**, tells you how current Corbis's data is. Both are free-tier reachable.
- **The backend is built and live-smoked.** As of 2026-06-26, `get_research_pulse` and `get_data_freshness` are registered, return schema-valid + leak-clean payloads over real HTTP, and the route contract suite passes. See `_recon/2026-06-26-live-smoke.md`.
- **ResearchBar is still a CodexBar shell in code.** The repo today is a quota-monitor menu-bar app (`UsageSnapshot` / provider-quota types). ResearchBar v0 means adding a research-domain layer (a `ResearchPulse` model, an MCP client, a credential store, a cache, a menu renderer), not bending the existing quota types into citations (`09-deep-dive-review-and-next-actions.md:27-30`).
- **Build fixtures-first.** Write the model, fixtures, client, cache, and renderer against local JSON fixtures. Switch to live calls only after a captured clean payload exists (it now does).

---

## 1. Quickstart: first live call in 3 steps

### Step 1: get a personal MCP token (a human does this once)

A Corbis user creates a personal MCP API key in the web app:

- **Settings → API Keys tab** (`app/(chat)/settings/settings-client.tsx`, renders `components/settings/mcp-api-keys-card.tsx`).
- The key is minted by the server action `createMcpApiKeyAction` (`app/actions/mcp-api-keys.ts:152`); the token format is `corbis_mcp_` + 48 random chars.
- **The raw token is shown exactly once.** Corbis stores only a SHA-256 hash (`tokenHash`), never the raw key (`app/actions/mcp-api-keys.ts:213`; validation re-hashes at `lib/mcp/auth.ts:73-106`). If the user loses it, they regenerate (which invalidates the old one).
- Guests cannot mint keys; there is a per-user cap (tier limit, hard max 50).

For ResearchBar v0 (private beta), the user pastes that `corbis_mcp_…` token into the app once. Public launch should move to a Corbis-managed device/OAuth flow with explicit storage and revocation (`build-guides/05-researchbar-native-client-plan.md`, "Auth for v0").

### Step 2: list tools (prove the token works)

```bash
BASE="https://www.corbis.ai"   # or http://localhost:3000 for local dev
curl -s -X POST "$BASE/api/mcp/universal" \
  -H "Authorization: Bearer $CORBIS_MCP_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":2,"method":"tools/list"}' \
  | jq '.result.tools[].name' | rg get_research_pulse
```

An authenticated token sees the full tool set; an anonymous or invalid token sees only tier1 tools. As of 2026-06-27 local source, this is 42 authenticated tools and 32 tier1 tools, but clients should trust `tools/list` because the registry can change. Both `get_research_pulse` and `get_data_freshness` must be present.

### Step 3: call the pulse and prove it is leak-clean

```bash
curl -s -X POST "$BASE/api/mcp/universal" \
  -H "Authorization: Bearer $CORBIS_MCP_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"get_research_pulse","arguments":{}}}' \
  | tee /tmp/research-pulse.json

# This grep MUST return nothing before ResearchBar renders a live payload:
rg -i 'openalex|semantic scholar|ssrn|backend|sourceId|authorId|openalexId' /tmp/research-pulse.json
```

(Canonical block: `09-deep-dive-review-and-next-actions.md:131-148`.)

---

## 2. The transport contract (read this once, carefully)

### Endpoint

- **`POST /api/mcp/universal`** is the one endpoint ResearchBar needs. The same route also serves `GET` (discovery / SSE) and `DELETE` (SSE session cleanup) (`app/api/mcp/universal/route.ts`). An SSE pair exists (`/api/mcp/sse` + `/api/mcp/message`) but is only enabled when the server has Redis; a native client should just POST JSON-RPC and ignore SSE.
- Server identity: `"Corbis MCP Server" v2.0.0`. It negotiates MCP protocol versions `2024-11-05`, `2025-03-26`, `2025-06-18` (default `2024-11-05`).

### Request envelope

Body must be `Content-Type: application/json` and a valid JSON-RPC 2.0 object. The route rejects anything where `jsonrpc !== "2.0"` or `method` is missing.

```jsonc
// tools/list
{ "jsonrpc": "2.0", "id": "tools-list", "method": "tools/list", "params": {} }

// tools/call: params is { name, arguments }; arguments is the tool input object
{ "jsonrpc": "2.0", "id": "1", "method": "tools/call",
  "params": { "name": "get_research_pulse", "arguments": {} } }
```

`get_research_pulse` and `get_data_freshness` both take **no arguments** (`arguments: {}`). The caller's identity comes from the bearer token, not from arguments.

### Success envelope (the part clients get wrong)

A successful `tools/call` returns **both** of these (`lib/mcp/result-format.ts:533-604`; route `app/api/mcp/universal/route.ts:1477-1485`):

- **`result.structuredContent`** = the **raw tool result object**. **This is what ResearchBar must decode.** It is the full `GetResearchPulseOutput` / `GetDataFreshnessOutput` payload.
- **`result.content[0]`** = `{ "type": "text", "text": "<markdown summary>" }`. This is a **human-readable digest**, often truncated or top-N. **Do not parse this for data.** A second `content` block may carry assistant-only guidance.
- **`result._meta`** = `{ responseChars, summaryChars, cached }`.

```jsonc
{
  "jsonrpc": "2.0",
  "id": "1",
  "result": {
    "structuredContent": { /* full GetResearchPulseOutput: DECODE THIS */ },
    "content": [ { "type": "text", "text": "Research pulse for … (markdown digest)" } ],
    "_meta": { "responseChars": 1234, "summaryChars": 456, "cached": false }
  }
}
```

### Two kinds of failure (handle both)

1. **Protocol-level JSON-RPC error**: top-level `error`, no `result`:
   ```jsonc
   { "jsonrpc": "2.0", "id": "1", "error": { "code": -32603, "message": "…", "data": { /* code, docs, retryable, requiredScopes, tier, … */ } } }
   ```
   Codes you may see: `-32700` parse error, `-32600` invalid request, `-32601` method not found, `-32602` bad params / tool-not-found, `-32603` internal / insufficient credits / tier / scope, `-32001` auth, `-32004` rate limit.

2. **Tool-level error inside a successful HTTP 200**: there is a normal `result` (no top-level `error`), but `result.structuredContent.status === "error"`. The tool ran and reported a domain failure. **ResearchBar must inspect `structuredContent` even on HTTP 200.**

### HTTP status codes

| Status | When |
|---|---|
| `200` | Normal result, tool-level errors, and even `Method not found` (the JSON-RPC error rides inside a 200). |
| `400` | Empty body, non-JSON content type (`"Expected JSON body"`), invalid JSON, or invalid JSON-RPC envelope. |
| `401` | Missing token on a protected method, or invalid/expired token. Carries `WWW-Authenticate: Bearer error="invalid_token", resource_metadata="<origin>/.well-known/oauth-protected-resource"`. |
| `429` | Rate limit (**200 requests/hour per authenticated principal**, `lib/mcp/auth.ts`). Carries `Retry-After` + `X-RateLimit-*`. Back off and surface a calm "try again later," never a tight retry loop. |
| `500` | Unhandled server error. |

### Auth header + query fallback

- Primary: `Authorization: Bearer <corbis_mcp_…>` (`lib/mcp/auth.ts:443-444`).
- Fallbacks exist as query params (`?apikey=` preferred, then `?token=`), but the server sets `Referrer-Policy: no-referrer` to limit leakage. **Prefer the header.** A native app can always set headers, so ResearchBar should use the header exclusively and never put the token in a URL it might log.

---

## 3. Auth: the simple path and the advanced path

### Personal MCP API key (use this for v0)

The bearer token is a personal key (`corbis_mcp_…`). The server's auth cascade tries, first match wins (`authenticateMCPRequest`, `lib/mcp/auth.ts:326-382`):

1. **Personal MCP API key** (prefix `corbis_mcp_`, SHA-256 hash lookup in `McpApiKey`).
2. Custom OAuth JWT (`aud: corbis-mcp-server`).
3. Global env API keys (`MCP_API_KEYS`): server/service accounts, not for ResearchBar.
4. Supabase OAuth JWT.
5. Supabase session JWT.

Default scopes granted to a personal key (`DEFAULT_MCP_SCOPES`, `lib/mcp/auth.ts:64-71`): `read:papers`, `read:economic_data`, `read:market_data`, `read:web`, `read:corbis`, `read:profile`, `read:documents`. That set covers every tool ResearchBar v0 needs.

**Per-key config** (optional, set in the web UI; `lib/mcp/config.ts`): a key can restrict `allowedToolNames`, set default model/reasoning/instructions, and set default journal/year filters for research tools. ResearchBar does not need to set any of this for v0, but be aware a user's key might be scoped down, in which case `tools/list` will show fewer tools.

### OAuth 2.1 / DCR (available, not required for v0)

Corbis also implements full OAuth 2.1: discovery at `/.well-known/oauth-protected-resource` and `/.well-known/oauth-authorization-server`, Dynamic Client Registration at `/api/mcp/oauth/register`, authorization-code + PKCE via `/api/mcp/oauth/authorize` (with a `/oauth/consent` UI) and `/api/mcp/oauth/token` (`lib/mcp/oauth-discovery.ts`). For stdio-only clients there is an `mcp-remote` bridge. **For ResearchBar, the personal API key is the simple path; OAuth 2.1 is the future path for per-user consent without distributing long-lived keys.** Treat OAuth as a public-launch upgrade, not a v0 requirement.

---

## 4. `get_research_pulse`: the v0 tool

Tool facts: scope `read:profile`, tier `tier1`, flat cost 0.5 credits, **not cached** (per-user state), no arguments (`lib/ai/capabilities/index.ts:648`; `lib/mcp/tools/output-schemas.ts:324`).

### Exact output schema (decode `structuredContent` into this)

This is the **live** schema (`lib/mcp/tools/output-schemas.ts:324-355`). Note: an older planning doc (`04`) typed the trend fields as hard `null` and the middle history state as `accruing`. **The shipped code is what follows**: trend fields are nullable numbers, and the middle state is `tracking`.

```ts
{
  profileStatus: "linked_researcher" | "profile_only" | "industry_profile" | "unlinked",
  displayName: string | null,
  affiliation: string | null,
  role: string | null,
  sector: string | null,
  companyName: string | null,
  plan: string,                 // effective tier label, e.g. "free"
  creditsRemaining: number,     // per-user; this is why the tool is never cached
  orcid: string | null,
  googleScholarId: string | null,
  googleScholarUrl: string | null,  // URL
  totalCitations: number | null,
  hIndex: number | null,
  trackedPaperCount: number | null,
  citationDelta7d: number | null,   // null until history accrues
  citationDelta52w: number | null,  // null until history accrues
  sparkline52w: number[] | null,    // null until history accrues
  citationHistoryStatus: "not_yet_tracked" | "tracking" | "tracked",
  lowConfidence: {
    identity: boolean,
    citations: boolean,
    reason: string | null,
  },
  profileLinks: { label: string, url: string }[],  // ORCID / Scholar / DOI / Corbis paper / vetted personal site only
  fetchedAt: string,   // ISO 8601
  staleAfter: string,  // ISO 8601: refresh after this
  etag: string,        // payload hash: use for cache validation
}
```

### `profileStatus`: render all four states

| State | Meaning | Render |
|---|---|---|
| `linked_researcher` | A verified researcher with resolved publication metrics. | Full pulse: name, affiliation, citations, h-index, trend (if `tracked`). |
| `profile_only` | A researcher profile exists but is not confidently linked / metrics unavailable. | Identity + whatever metrics are non-null; show the low-confidence hint. |
| `industry_profile` | A non-publishing / industry user. | A useful professional pulse with **null** publication metrics. Do not show empty citation widgets as zeros. |
| `unlinked` | No public anchor and no professional profile. | A "link your identity" call to action, not an error. |

`unlinked` and `industry_profile` are first-class, not failure cases. A user must always get a usable pulse, never an error screen, when the call succeeds.

### `lowConfidence`

`lowConfidence.identity` is true unless the user is a confidently linked researcher whose author refresh succeeded; `lowConfidence.citations` is true when no refreshed metrics are present; `reason` is a human string or null. When either flag is true, show a subtle "low confidence" affordance rather than presenting numbers as authoritative.

### Trend / sparkline rules (do not fabricate)

- Draw a sparkline or a delta **only** when the trend fields are non-null **and** `citationHistoryStatus === "tracked"`.
- For `"not_yet_tracked"` show a "tracking will begin" affordance. For `"tracking"` show "history is accruing," not a flat zero line.
- **Never render a zero trend or a synthetic sparkline.** A null trend means "no data," which is visually different from "zero change." This is a hard product rule (`08-get-research-pulse-v0-spec.md` §3; `build-guides/05`).

Trends populate automatically once the backend's weekly citation-snapshot cron accumulates history (Corbis Phase 1, already built). ResearchBar does not poll for this; it just renders whatever the server returns.

---

## 5. `get_data_freshness`: the "how current is the data" tool

Tool facts: scope `read:market_data`, tier `tier1`, flat cost 0.5, **cacheable**, no arguments (`lib/ai/capabilities/index.ts:659`; `lib/mcp/tools/output-schemas.ts:363`).

```ts
{
  sources: {
    id: "academic_corpus" | "cre_market_data" | "economic_data",
    label: string,
    status: "available" | "live" | "unknown",
    dataThrough: string | null,           // e.g. "2026" or "2026-06-20"
    dataThroughGranularity: "day" | "month" | "year" | null,
    lastRefreshedAt: string | null,
    note: string | null,
  }[],
  overallStatus: "ok" | "partial" | "unavailable",
  fetchedAt: string,
  staleAfter: string,
  etag: string,
}
```

`dataThrough` is honest: a source with no fixed cutoff (e.g. economic data that is queried live) returns `status: "live"` with `dataThrough: null` rather than a fabricated date. Render "live" differently from a dated cutoff.

---

## 6. Linking a researcher identity over MCP

ResearchBar can drive the full identity handshake over MCP (both tools are `read:profile`, `tier1`, so a v0 token reaches them). The internal author id is **resolved server-side and never returned**; the client only ever handles public anchors and an opaque token.

### `find_academic_identity` (search)

- Input (`lib/ai/tools/find-academic-identity.ts:11-20`): `{ nameOverride?: string, institutionOverride?: string }`. With no overrides it searches using the user's stored Corbis profile. The caller never supplies an author id.
- Output (`lib/mcp/tools/output-schemas.ts:49-67`): `{ found, message, alreadyLinked?, candidate?: { candidateToken, name, institutions: string[], worksCount, citedByCount, orcid, topWorks[], confidence, status } }`.
- `candidateToken` is an **opaque, AES-256-GCM-encrypted, 24h-TTL** blob that hides the internal author id (`lib/research-profile/author-candidate-service.ts:145-199`). There is **no `authorId` / `openalexId`** in the output by design.

### `confirm_academic_identity` (accept / clear)

- Input (`lib/ai/tools/confirm-academic-identity.ts:32-63`, strict): `{ action: "accept" | "clear", candidateToken?, orcid?, googleScholarId?, googleScholarUrl?, authorName?, confidenceScore? }`.
- `accept` requires **at least one anchor**: `candidateToken` OR `orcid` OR a Google Scholar id/url. `confidenceScore` (0-100) is advisory only and never gates trust.
- Output (`output-schemas.ts:69-76`): `{ success, message, action?, orcid?, googleScholarId?, googleScholarUrl? }`. **No internal id is echoed.**

### Client handshake

1. (Optional) Set the user's name/institution first, or pass `nameOverride`/`institutionOverride` to seed the search.
2. Call `find_academic_identity` → show the redacted `candidate` to the user.
3. On user confirm, call `confirm_academic_identity` with `action: "accept"` and the `candidateToken` (or an ORCID / Scholar id the user typed).
4. Re-fetch `get_research_pulse`; `profileStatus` should now reflect the link.

---

## 7. Billing and the free-allowance caveat

- **Flat cost: 0.5 credits per `tools/call`** (`MCP_CREDIT_COST`, `lib/mcp/tool-credits.ts:16`). `tools/list` is free.
- The route **reserves before executing and refunds on tool failure** (`app/api/mcp/universal/route.ts`, reserve ~`:1382`, refund ~`:1438`). A failed tool call does not cost the user; a successful one does. Cached results still reserve but skip re-execution.
- **Free-allowance math (planning, not a hard fact):** code fallbacks suggest a free user has on the order of 50 lifetime/period credits, i.e. roughly 100 aggregate calls at 0.5 each. These are DB-driven defaults that can change; **do not freeze any credit number, price, or allowance into ResearchBar.** Read `creditsRemaining` from the pulse and show it; do not compute entitlements client-side.
- **Design for frugal calls.** Refresh on menu-open when the cache is stale, plus an explicit manual refresh. **Do not background-poll.** A 30-second poller would burn a free user's allowance in under an hour.
- If you see a diagnostics panel claiming "1 credit per call," that is a stale display value; the authoritative cost is **0.5** (`lib/mcp/tool-credits.ts:16`).

> **Open founder decision that affects you:** there is **no install-attribution column** in the Corbis schema today, so a ResearchBar-specific free allowance (distinct from ordinary Corbis free-tier credits) does not exist yet and needs backend schema/tier work. Until that lands, a ResearchBar user consumes ordinary Corbis credits. Track this in `founder-decisions.md` (C1/C2) and `06-risks-and-open-questions.md`.

---

## 8. Redaction rules the client MUST honor (hard)

These are non-negotiable. The backend redacts by construction and a test enforces it; the client adds a second, defensive layer.

1. **Never surface or log the internal author id pattern `/^A\d+$/`** (e.g. `A5012345678`) in any field, URL, label, or log line.
2. **Never surface or log backend/provider/source names**: `openalex`, `semantic scholar`, `ssrn`, `hybrid_search`, or low-level keys like `sourceId` / `authorId` / `openalexId`. Links may only be ORCID, DOI, a Corbis paper page, Google Scholar, or a vetted personal/work site.
3. **Ship a client-side redaction assertion** (`ResearchBarRedaction.swift`): a leak-like fixture must **fail tests**; in release, a payload that trips the assertion shows a safe error instead of rendering.
4. **Never render a fake sparkline or a zero trend** (see §4).
5. **v0 calls only the aggregates** (`get_research_pulse`, `get_data_freshness`) and the two identity tools. Do **not** orchestrate low-level paper/citation MCP tools from ResearchBar yet; broader low-level redaction is a tracked Corbis follow-up (see `TODO.md` A4b and the evaluation `CLAUDE.md` gotchas), and those tools still surface corpus identifiers their own contracts require.

Why this matters: the product promise is a research pulse that never leaks the plumbing. A single `openalex.org` URL or `A123…` string in a tooltip breaks it. The grep in §1/Step 3 is your gate.

---

## 9. Caching, freshness, and account-keying

Every aggregate response carries `fetchedAt`, `staleAfter`, and `etag`.

- **Account-key the cache.** The cache key must include the Corbis account identity (derive it from the token, e.g. a hash of the token, not the raw token). When the token changes or is removed, clear or partition the cache. Never serve one account's pulse to another. (The backend's own cache is deliberately user-blind, which is exactly why per-user state like the pulse is **not** server-cached; the client owns per-user caching.)
- **Honor `staleAfter`.** Serve from cache until `staleAfter`; refresh on menu-open when stale, plus manual refresh. No background timers in v0.
- **Use `etag`** for change detection between renders to avoid redundant redraws.

---

## 10. Native client (Track B) build plan

Target repo: **`Agentic-Assets/ResearchBar`** (local path `…/agentic-assets/ResearchBar`). Today it is a CodexBar fork: a Swift Package / SwiftUI menu-bar app (`NSStatusItem`) with provider-auth patterns, Sparkle packaging, a CLI, and test scaffolding. Build/verify with `swift build`, `make test`, `make check` (`09-deep-dive-review-and-next-actions.md:122-127`).

**Phase 0B client checklist** (`build-guides/05-researchbar-native-client-plan.md`; `09:93-99`). Build and test each entirely on fixtures first:

- [ ] `ResearchPulse.swift`: `Codable` model matching §4 exactly (nullable trends, the three-state `citationHistoryStatus`, the freshness triplet). A matching `DataFreshness.swift` for §5.
- [ ] `ResearchPulseFixtures.swift`: one fixture per state: `linked_researcher`, `profile_only`, `industry_profile`, `unlinked`, null-trend, tracked-trend, stale, and a **leak-like** fixture (contains `A123…` / `openalex`) that the redaction test must reject.
- [ ] `CorbisMCPClient.swift`: JSON-RPC over `URLSession`: builds the envelope (§2), sets the bearer header, decodes `result.structuredContent`, and maps both failure modes (protocol error vs `structuredContent.status == "error"`) plus the HTTP status table to typed Swift errors.
- [ ] `CorbisCredentialStore.swift`: Keychain-backed token storage. No plaintext token in `UserDefaults`/preferences. Support connect / reconnect / unlink.
- [ ] `ResearchPulseCache.swift`: account-keyed, honors `staleAfter` / `etag`, clears on token change, no background polling (§9).
- [ ] `ResearchPulseMenuModel.swift` + `ResearchPulseMenuFactory.swift`: descriptor-driven menu renderer covering all four `profileStatus` states and the trend rules. Never draws a sparkline unless trends are non-null and status is `tracked`.
- [ ] `ResearchBarRedaction.swift`: defensive client-side redaction assertions (§8).
- [ ] `CorbisSettingsView.swift`: paste-token onboarding (v0), connection diagnostics, unlink.

**Live cutover gate:** swap fixtures for live calls **only after** the Corbis live smoke produces a captured clean payload. It now exists (`_recon/2026-06-26-live-smoke.md`), so live mode is unblocked, but keep the fixture suite as the test backbone.

**Do not** reuse the existing quota-monitor types (`UsageSnapshot`, provider-quota semantics) for research data. Add a parallel research-domain layer; the two are different domains and conflating them is called out as a mistake in `09`.

---

## 11. Error-handling matrix for the client

| Symptom | Cause | Client behavior |
|---|---|---|
| HTTP 401 + `WWW-Authenticate` | Missing/expired/invalid token | Prompt reconnect; clear cached pulse for that account. |
| HTTP 429 + `Retry-After` | Rate limit (200/hr) | Back off to `Retry-After`; show calm "try again shortly." Never tight-loop. |
| HTTP 400 | Malformed request | Bug in the client envelope; fix the request, do not retry blindly. |
| HTTP 200, top-level `error` | Protocol JSON-RPC error (e.g. `-32603` insufficient credits, scope, tier) | Read `error.data` for `code`/`requiredScopes`/`tier`; for insufficient credits show an upgrade hint, not a crash. |
| HTTP 200, `structuredContent.status == "error"` | Tool-level domain error | Render the tool's safe error message; do not treat as success. |
| Payload trips redaction assertion | Unexpected leak | Show safe error, log a redacted diagnostic, do **not** render. |
| `profileStatus == "unlinked"` | No identity linked | Show the link-identity CTA (§6), not an error. |

---

## 12. Folder map of this planning package (`docs/researchbar-evaluation/`)

Numbered deliverables (read order; authoritative one-liners from `README.md`):

| File | Purpose |
|---|---|
| `01-inventory-what-exists-today.md` | File-level map of current identity, MCP, and research-profile capabilities vs concept requirements. |
| `02-gap-analysis.md` | Concept requirement vs exists/gap/effort/risk table. |
| `03-design-review.md` | Critique of API design, credit model, caching, ORCID migration, link resolution, the never-surface rule. |
| `04-revised-corbis-api-contracts.md` | Recommended MCP tool names + JSON request/response shapes. **Note:** predates code on two labels (trend nullability, `accruing` vs `tracking`); §4/§5 of *this* guide reflect shipped code. |
| `05-revised-implementation-plan.md` | Corbis Track A phased plan (files, migrations, tests, smoke commands, per-phase "done when"). |
| `06-risks-and-open-questions.md` | Risk checklist; founder-only decisions (free allowance, ToS, corpus figure). |
| `07-adversarial-review-verdict.md` | What the concept got right/wrong; what would fail in production if built as written. |
| `08-get-research-pulse-v0-spec.md` | Implementation-ready spec for the pulse (schema, service layout, billing rule, test plan). |
| `09-deep-dive-review-and-next-actions.md` | Cross-repo synthesis; current ResearchBar fork reality; build sequence; the canonical live-smoke curl block. |

Support:

| Path | Purpose |
|---|---|
| `RESEARCHBAR-CLIENT-INTEGRATION-GUIDE.md` | **This file**: the client onboarding guide. |
| `build-guides/` | Modular phase guides. `05` is the ResearchBar native-client (Track B) plan. `build-guides/` wins over `subagent-reports/` on conflict. |
| `_recon/` | Agent scratch evidence + `2026-06-26-live-smoke.md` (the captured clean payload that unblocks live mode). Every deliverable claim traces to `file:line` here. |
| `subagent-reports/` | Preserved dated lane reports (support material). |
| `founder-decisions.md` | C1-C5 business/brand/legal calls (free allowance, subsidy, naming, ToS, corpus figure). Blocks public launch, not code. |
| `TODO.md` | Live actionable cut of remaining end-to-end work. |
| `README.md` | Package index, "BUILD WITH CHANGES" verdict, reading order, scope boundary. |
| `CLAUDE.md` | Module rules for agents working in this planning tree (Track A planning only). |

---

## 13. Open questions and gates that affect the client

From `06-risks-and-open-questions.md` and `founder-decisions.md` (founder calls, not yours to make, but they shape what you build):

- **Free-allowance model + install attribution** (C1): no attribution column yet; a ResearchBar-only allowance needs backend work. Until then, ResearchBar users spend ordinary Corbis credits.
- **Whether Corbis subsidizes the first calls** (C2).
- **Product naming** (C3): "ResearchBar" vs a Corbis-branded name. Keep brand strings configurable so a rename is a one-line change.
- **ToS posture** (C4): Google Scholar, SSRN, Semantic Scholar, ResearchGate, ORCID Member API. The client must not scrape any of these directly; it only ever reads what Corbis returns.
- **Corpus figure** (C5): if ResearchBar ever shows a corpus count, quote it **only** from live corbis.ai, never a hardcoded number.

---

## 14. Source of truth (re-verify before trusting memory)

- **Wire schemas:** `lib/mcp/tools/output-schemas.ts` (`GetResearchPulseOutput` ~`:324`, `GetDataFreshnessOutput` ~`:363`).
- **Transport + billing route:** `app/api/mcp/universal/route.ts`. **Result shaping:** `lib/mcp/result-format.ts`. **Cost:** `lib/mcp/tool-credits.ts:16`.
- **Auth + scopes:** `lib/mcp/auth.ts` (`authenticateMCPRequest` `:326`, `DEFAULT_MCP_SCOPES` `:64`). **Key minting:** `app/actions/mcp-api-keys.ts`. **Scope/tier per tool:** `lib/ai/capabilities/index.ts:626,638,648,659`.
- **Identity tools:** `lib/ai/tools/find-academic-identity.ts`, `lib/ai/tools/confirm-academic-identity.ts`, candidate token `lib/research-profile/author-candidate-service.ts`.
- **Pulse assembly:** `lib/research-profile/research-pulse.ts`.
- **Live route contract test:** `tests/routes/mcp-tools-comprehensive.test.ts`. **Offline parse + leak smoke:** `pnpm researchbar:offline-smoke`.
- **Captured clean payload:** `_recon/2026-06-26-live-smoke.md`.
- **Module rules / reading order:** `README.md`, `CLAUDE.md`, `08`, `09`, `build-guides/05`.

When this guide and the code disagree, the code is right and this guide is stale; fix the guide and bump `as_of`.
