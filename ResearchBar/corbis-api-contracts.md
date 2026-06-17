# Corbis API contracts for ResearchBar

This file specifies the **aggregate MCP tools and endpoints** ResearchBar calls. It is the build target for `agentic-assets-app`. The ResearchBar fork should not orchestrate low-level tool fan-out (`search_papers` plus `get_paper_details` loops) for menu panels; it calls these aggregates and renders the JSON.

Full identity, consolidation, and never-surface rules live in `identity-and-data-consolidation.md`.

## Design rules

1. **One panel, one call (ideal).** Each menu section maps to a single aggregate endpoint where possible.
2. **Every record carries links.** Corbis resolves `url` (and optional `corbisPaperUrl`, `doiUrl`, `pdfUrl`) so the client only opens links; it never constructs them.
3. **ORCID is the public key.** Responses surface ORCID; internal backend IDs never appear in client-facing fields.
4. **Credits bill per aggregate call**, not per internal fan-out. The service absorbs orchestration cost inside one credit (product decision; see `funnel-economics.md`).
5. **Cache-friendly.** Responses include `fetchedAt`, `staleAfter`, and optional `etag` so the client's GRDB cache can respect server freshness.

## Corbis-owned aggregates (build in `agentic-assets-app`)

These are reusable by corbis.ai web, EQUIRE, and future surfaces, not ResearchBar-only.

### `get_research_pulse`

Daily-glance identity and citation summary. Replaces client-side delta math and multi-tool citation pulls.

**Returns (illustrative shape):**

| Field | Description |
|---|---|
| `orcid` | Public identity anchor |
| `displayName` | Consolidated author name |
| `affiliation` | Current institution (from consolidation service) |
| `creditsRemaining` | Corbis account credits |
| `plan` | Corbis plan label |
| `totalCitations` | Consolidated, cross-verified count |
| `citationDelta7d` | Change over 7 days |
| `citationDelta52w` | Change over 52 weeks |
| `sparkline52w` | Array of weekly citation totals for menu icon and panel |
| `hIndex` | Consolidated career metric (optional; premium tier may add Scholar) |
| `trackedPaperCount` | Works in the user's consolidated bibliography |
| `lowConfidence` | Boolean or per-metric flags when sources disagreed beyond threshold |
| `profileLinks` | Array of `{ label, url }` (ORCID page, institutional page, etc.; Corbis-resolved) |
| `fetchedAt`, `staleAfter`, `etag` | Freshness metadata |

### `get_new_work_radar`

Who cites you, subfield preprints, and related work. Replaces multi-search orchestration.

**Returns:**

| Field | Description |
|---|---|
| `citingYou` | Papers newly citing the user's works; each item has `title`, `subtitle`, `url`, `corbisPaperUrl` |
| `subfieldAlerts` | Preprints in user's field presets; Corbis-branded labels only (no raw source names) |
| `relatedToProjects` | Items tied to active projects the user tracks in Corbis |
| `fetchedAt`, `staleAfter`, `etag` | Freshness metadata |

### `get_data_freshness`

Finance and real estate data-release calendar. Replaces FRED plus CRE tool fan-out.

**Returns:**

| Field | Description |
|---|---|
| `items` | Release and update events: FRED series, CRE market metrics, dataset availability |
| `fieldPreset` | Active preset (e.g. finance, real estate) |
| `fetchedAt`, `staleAfter`, `etag` | Freshness metadata |

Each item includes `title`, `summary`, `releasedAt` or `updatedAt`, and `url` where applicable.

### `get_conference_deadlines`

Curated conference calendar plus per-user overrides. Stored and maintained server-side.

**Returns:**

| Field | Description |
|---|---|
| `deadlines` | Conference name, milestone type (abstract, submission), due date, days remaining |
| `userAdded` | User overrides merged with curated seed |
| `url` | Conference or CFP link per item |
| `fetchedAt`, `staleAfter`, `etag` | Freshness metadata |

### Identity (existing tools, extend for ORCID-first parity)

| Tool | Role |
|---|---|
| `find_academic_identity` | Propose match; candidate labeled by ORCID; rich shape should match web `/api/user/author-link/candidate` (h-index, top works, profile links) |
| `confirm_academic_identity` | Confirm by ORCID (target); link to account server-side |

## Split ownership: Corbis plus ResearchBar

Some features span server intelligence and macOS-local capability. The split is explicit so neither repo over-builds.

### Linked replication repos

| Layer | Owner | Responsibility |
|---|---|---|
| **Corbis** | `get_linked_repos` (or section inside `get_research_pulse`) | Paper-to-repo associations the user configured; remote GitHub metadata (CI status, stars, default branch) when account is linked |
| **ResearchBar** | Local merge only | Scan local filesystem for clone paths; compute ahead/behind/dirty; merge onto Corbis repo records at render time |

Corbis does not need filesystem access. ResearchBar does not own paper-to-repo mapping logic or GitHub API polling if Corbis can serve remote state.

**Open product call:** whether `get_linked_repos` ships as its own MCP tool or as a nested block inside another aggregate. Default: own tool in Phase 2, optional nesting later.

### Agent catalog and launch

| Layer | Owner | Responsibility |
|---|---|---|
| **Corbis (optional later)** | `get_agent_catalog` MCP tool | Canonical skills, agents, slash commands metadata for any surface |
| **ResearchBar (v1 default)** | Local plugin read | Read installed Corbis plugin `plugin.json` and skill paths for the browse-and-launch menu; spawn `claude` CLI with pre-filled skill |

v1 keeps the catalog read in ResearchBar because launch is macOS-local (subprocess, Claude Code install path) and the plugin files are already on disk. If corbis.ai later needs the same catalog in-browser, promote `get_agent_catalog` to Corbis and have ResearchBar call it instead of parsing local files. Not blocking for Phase 0 or Phase 1.

## What already exists in `agentic-assets-app` (inventory)

Build aggregates on top of this; do not duplicate in ResearchBar.

| Piece | Location | Notes |
|---|---|---|
| Identity search MCP | `lib/ai/tools/find-academic-identity.ts` | Returns candidate with ORCID; confirm key still OpenAlex today |
| Identity confirm MCP | `lib/ai/tools/confirm-academic-identity.ts` | Target: ORCID-first confirm |
| OpenAlex linking | `lib/research-profile/openalex-linking.ts` | Scoring, auto/suggest thresholds |
| Author linking service | `lib/research-profile/author-linking-service.ts` | Profile plus SSRN refresh |
| ORCID enrichment | `lib/research-profile/orcid-enrichment.ts` | Employment, websites |
| SSRN scraper | `lib/research-profile/ssrn-scraper.ts` | Server-side only |
| Web candidate API | `app/api/user/author-link/candidate/route.ts` | Richer than MCP today (h-index, websites, top works) |
| Academic identity UI | `components/settings/academic-identity-card.tsx` | Web reference for MCP parity |
| Paper batch fetch | `get_paper_details_batch` in MCP registry | Up to 25 papers; use inside aggregates |
| Native MCP tools | `lib/mcp/tools/registry.ts` | 24 tools; building blocks for aggregates |

**Gap:** no `get_research_pulse`, `get_new_work_radar`, `get_data_freshness`, or `get_conference_deadlines` yet. Multi-source citation reconciliation and ORCID-first confirm are partial.

## ResearchBar client allowlist

ResearchBar MAY contain:

- CodexBar shell (`NSStatusItem`, menus, settings, Sparkle, Homebrew)
- Corbis auth (OAuth or API key in Keychain)
- Thin onboarding UI (confirm/cancel over `find` / `confirm` academic identity)
- Generic panel renderer for aggregate JSON
- Polling timer plus GRDB response cache (not source logic)
- `UNUserNotificationCenter` on server-flagged deltas
- Agent subprocess launch (Claude Code)
- Local git clone scanner merged onto Corbis repo records
- v1 agent catalog from local plugin install

ResearchBar MUST NOT contain:

- Source adapters, scrapers, reconcilers
- Multi-tool MCP orchestration for menu panels
- Citation delta or sparkline computation
- Deadline curation or storage
- Subfield preset definitions
- External URL discovery logic
- Paper-to-repo association persistence (unless deferred entirely to user settings in Corbis)
