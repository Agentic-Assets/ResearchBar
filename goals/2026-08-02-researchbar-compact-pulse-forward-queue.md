---
date: 2026-08-02
type: forward-queue
tags: [researchbar, corbis, menu-bar, ui]
---

# Forward queue: compact ResearchBar research pulse

## Ready for review

- Review the compact card on a real, authorized Corbis research profile after the draft PR is reviewed. Check readability at the target menu-bar scale, action focus order, stale-data wording, and the expected narrow provider-card width.
- If the card is accepted, merge only with Cayman approval and run the normal signed-release and client-acceptance gates separately.

## Follow-up only if evidence requires it

- Add a fixture-based visual snapshot when the supported macOS UI-test harness can capture menu cards reliably; keep it free of real Corbis credentials and profile data.
- Revisit the card projection if the server publishes a dedicated compact display contract. Until then, preserve source-specific labels and the fail-closed behavior introduced here.
