"""No-API-key cover image providers (SMP-330).

Three providers chained by ``CoverImageService`` (highest signal first):

1. ``wikipedia`` — REST summary endpoint, lead image of the matching
   article. Multilingual (locale-driven) and exposes the article's
   coordinates so downstream providers can target the same place.
2. ``wikidata`` — entity P18 (Image), used when the Wikipedia title is
   ambiguous (``Paris`` → which Paris?) or the article has no lead
   image but the entity does.
3. ``commons`` — Wikimedia Commons geosearch around coordinates;
   surfaces multiple alternatives even when Wikipedia is silent, which
   feeds the "Change cover" picker in the mobile UI.

If all three miss, the orchestrator returns ``None`` and the mobile UI
falls back to its built-in gradient placeholder. Adding an OSM tile
compositor as a fourth source would require Pillow (~50MB) for a case
that empirically never fires for populated places — deferred.

All providers share the courteous Wikimedia ``User-Agent`` from ``_http``
(API policy requires one with a contact URL) and the same generous-but-
bounded timeout so a hung provider can't wedge trip creation.
"""
