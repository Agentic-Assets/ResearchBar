# Redacted smoke examples

## `research-pulse-v0-clean.example.json`

A redacted, schema-valid example of a clean `get_research_pulse`
`structuredContent` payload, used as the build-plan `08` clean wire-shape
artifact.

### Provenance

Structure is grounded in the live MCP smoke recorded on the Corbis side at
`../../../../agentic-assets-app/docs/researchbar-evaluation/_recon/2026-06-26-live-smoke.md`.
That smoke (2026-06-26, real HTTP, valid `corbis_mcp_` token) verified:

- `tools/call get_research_pulse` returns a payload validating against
  `GetResearchPulseOutput`.
- `profileStatus`: `linked_researcher`.
- `citationHistoryStatus`: `not_yet_tracked`, with `citationDelta7d`,
  `citationDelta52w`, and `sparkline52w` all null (no weekly snapshots yet).
- Leak-grep (`openalex|semantic scholar|"sourceId"|"authorId"|openalexId|hybrid_search`)
  returned nothing on the real payload.

### Redaction

The Corbis recon deliberately keeps no token, account name, affiliation, ORCID,
or exact credit balance in the repo (PII and secrets stay out). This example
therefore carries the verified contract shape with every identity / account
field replaced by an obvious placeholder (`Dr. Example Researcher`,
`Example University`, `0000-0000-0000-0000`, `sha256:redactedexampleetag`,
representative `creditsRemaining`). The metric values are illustrative, not a
live capture. No backend provider names or internal author ids appear, matching
the guide §8 redaction rules.

This file is documentation and a leak-clean shape reference, not a
provenance-backed live capture and not a test fixture. The XCTest backbone uses
`Tests/CodexBarTests/Fixtures/ResearchBar/pulse-*.json`.
