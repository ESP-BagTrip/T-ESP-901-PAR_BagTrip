"""Golden-dataset eval harness for the AI workflows.

This package holds the regression suite that runs every AI workflow
(W1 inspire, W2 full plan, W3 post-trip) against curated golden
inputs with stubbed Amadeus / Open-Meteo / LLM responses. The
assertions pin **structural** invariants the audit explicitly called
out as broken on the legacy stack:

- W1: every shipped destination carries a 3-letter IATA, a non-empty
  country, and a cover image URL.
- W2: dates round-trip from input to DTO (no ``today+30`` fallback);
  a same-country short-distance origin/destination pair routes via
  TRAIN, never FLIGHT; the LLM-only sub-tasks ship even when Amadeus
  is down; budget breakdown contains every category.
- W3: the matched destination is one of the catalogue rows, never an
  LLM-invented city; the narration ships 3-6 activities.

The harness is plain pytest. It runs with the regular suite — no new
process, no separate runner. CI will fail on regression.
"""
