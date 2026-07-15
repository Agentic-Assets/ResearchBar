# Forward queue after ResearchBar academic profile v1 (2026-07-15)

Candidate work surfaced during the implementation. This is a menu, not a
roadmap. Verify each item before acting.

## Hardening

- **Add a public-schema drift fixture gate** (priority: high; confidence: verified gap)
  Generate or validate the Swift fixture shape against the pinned Corbis MCP
  output schema so internal server fields cannot accidentally enter the client
  contract again.
- **Run same-session live cutover proof** (priority: high; confidence: verified gap)
  With explicit operator authorization, capture a current leak-clean MCP payload,
  package ResearchBar, launch through `Scripts/launch.sh`, and verify the exact
  bundle renders the expected academic state. Keep API and native proof separate.

## Robustness

- **Add unknown-field telemetry without payload logging** (priority: medium; confidence: hypothesis)
  Record only contract version and safe failure categories when the nested profile
  is quarantined. This would reveal backend drift without storing academic data.

## Simplification

- **Retire legacy academic aliases after client adoption** (priority: medium; confidence: future dependency)
  Once a compatible ResearchBar release is deployed and measured, coordinate a
  versioned Corbis removal of deprecated academic aliases. Do not remove credit or
  trend fields, which remain separate pulse data.

## New capability

- **Version a server-owned display projection** (priority: medium; confidence: verified boundary)
  If ResearchBar needs the richer Corbis Settings work table, add an explicit
  public display projection in Corbis first. Do not recreate venue selection,
  publication classification, or canonical-manifestation policy in Swift.

## Evaluation

- **Validate compact-menu legibility in the macOS VM** (priority: medium; confidence: verified proof gap)
  Exercise sparse, partial, unavailable, and proposal-heavy fixtures in the
  packaged app, capturing light/dark screenshots and checking truncation and
  VoiceOver labels without contacting live providers.
