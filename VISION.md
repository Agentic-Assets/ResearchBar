# Vision

ResearchBar is a Corbis-gated macOS menu bar surface for academic researchers. It should make a researcher's scholarly pulse visible at a glance: identity, citations, tracking status, profile links, data freshness, research radar, replication repo status, and agent launch. The intelligence belongs in Corbis. The fork stays a fast, privacy-careful native renderer and launcher.

ResearchBar inherits CodexBar as upstream shell context: menu bar lifecycle, settings, refresh mechanics, packaging, and provider-oriented UI patterns are useful starting points. Preserve inherited AI provider usage code while Track B proves the Corbis pulse path, because it keeps upstream pulls easier and may become a small optional ResearchBar surface. The default product is no longer a general AI provider quota monitor.

## Guardrails

- Corbis owns identity resolution, citation consolidation, source adapters, billing, rate limits, and redaction.
- ResearchBar owns native auth handoff, local cache, menu rendering, notifications, local git merge, and optional local agent launch.
- Inherited CodexBar provider usage may stay as hidden machinery, diagnostics, or a small optional panel, but it does not lead the product.
- ORCID is the client-facing identity anchor. Internal backend ids and backend names do not appear in UI.
- The first live panel waits for Corbis `get_research_pulse` v0, ORCID-first confirm, and backend redaction.
- Null trend fields render as tracking states, not fake zeros or empty sparklines.
- Polling respects `staleAfter`, `etag`, and Corbis credit burn.

## Merge by Default

- Performance improvements, unless they add too much complexity.
- Bug fixes with clear cause and bounded risk.
- Small UI or UX tweaks that preserve the Corbis-thin-client boundary.
- Documentation fixes.
- Fixture-backed model, cache, and renderer tests for the pulse contract.

## Needs Sign-Off

- New features.
- Package, dependency, or toolchain changes.
- Broad refactors or architecture changes.
- Changes that add meaningful maintenance complexity.
- Behavior changes that affect Corbis auth, data storage, releases, billing, or user privacy.
- Provider additions or research data integrations that need new host APIs, bespoke UI, broad filesystem access, or unclear auth/privacy behavior.
- Global package, bundle id, Sparkle feed, or product rename work.
- Broad removal of inherited CodexBar provider usage before the research pulse works and the upstream sync strategy is clear.
- Any client-side source adapter, scraper, citation reconciliation, or deadline curation.
