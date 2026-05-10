"""Curated catalogue of destinations consumed by the post-trip RAG.

The list is intentionally small and opinionated — ~40 cities that
cover the main travel intents ("beach + party", "ancient history",
"food + culture", "nature + hiking", "ski", …) and a balanced
geographical spread. Adding rows is cheap (just append to
:data:`CATALOG`); dropping rows requires a follow-up migration to
clear the bootstrap table since the bootstrapper is idempotent and
will not delete entries that disappear from this module.

Each entry's ``types_tags`` is the canonical free-form bag of
descriptors the BGE-M3 embedder uses to compare against user
feedback. ``summary`` is the user-facing description we feed back
into the LLM narrative when the destination is picked.
"""

from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class CatalogEntry:
    iata: str
    city: str
    country: str
    country_code: str
    region: str
    types_tags: str
    summary: str
    avg_summer_temp_c: int
    avg_winter_temp_c: int
    daily_budget_eur: int
    typical_duration_days: int


# fmt: off
CATALOG: list[CatalogEntry] = [
    # ── Europe — culture / city break ────────────────────────────────
    CatalogEntry("CDG", "Paris", "France", "FR", "Europe",
        "culture, museums, gastronomy, romance, architecture, fashion, night walks",
        "Paris is a layered city for couples and culture seekers — Louvre, Marais walks, café terraces and Seine sunsets.",
        22, 6, 130, 5),
    CatalogEntry("FCO", "Rome", "Italy", "IT", "Europe",
        "ancient history, ruins, Italian food, walking tours, art, basilicas",
        "Rome rewards slow walkers — open-air ruins, Trastevere dinners and the Vatican in a single morning.",
        29, 9, 110, 5),
    CatalogEntry("BCN", "Barcelona", "Spain", "ES", "Europe",
        "beach, tapas, Gaudí architecture, nightlife, gothic quarter, sunshine",
        "Barcelona blends Mediterranean beach time with Gaudí's architecture and tapas bars open late.",
        27, 11, 95, 5),
    CatalogEntry("LIS", "Lisbon", "Portugal", "PT", "Europe",
        "coastal city, viewpoints, fado, pastel de nata, surf trips, affordable",
        "Lisbon is hilly, sunny and cheaper than its peers — Alfama walks, surf at Caparica, late dinners and fado.",
        26, 11, 75, 4),
    CatalogEntry("LHR", "London", "United Kingdom", "GB", "Europe",
        "museums, theatre, parks, history, shopping, multicultural food",
        "London is the museum + theatre + park stack — free national museums, West End shows and boroughs each with a different cuisine.",
        21, 6, 160, 4),
    CatalogEntry("AMS", "Amsterdam", "Netherlands", "NL", "Europe",
        "canals, biking, museums, design, coffee shops, easy walks, nightlife",
        "Amsterdam is bike-first — canal rides, Vermeer at the Rijks, bar-hopping in Jordaan.",
        21, 4, 120, 4),
    CatalogEntry("VIE", "Vienna", "Austria", "AT", "Europe",
        "imperial history, opera, coffee houses, classical music, museums",
        "Vienna is a slow-paced classical city — coffee houses, opera, palaces and a strong Christmas market in winter.",
        24, 2, 100, 4),
    CatalogEntry("PRG", "Prague", "Czechia", "CZ", "Europe",
        "old town, baroque architecture, beer, affordable, dense walks",
        "Prague packs a thousand-year old town into a tight, walkable footprint — beer-garden friendly in summer.",
        23, 1, 70, 3),
    CatalogEntry("ATH", "Athens", "Greece", "GR", "Europe",
        "ancient history, ruins, Mediterranean food, day-trip islands, sunshine",
        "Athens is the launchpad for island hops — Acropolis at dawn, fish taverns, Aegina ferries.",
        32, 11, 85, 5),
    CatalogEntry("CPH", "Copenhagen", "Denmark", "DK", "Europe",
        "design, biking, food, harbour, slow travel, cafés, hygge",
        "Copenhagen is design-driven — harbour swimming in summer, smørrebrød lunches, Tivoli at dusk.",
        20, 2, 150, 4),

    # ── Europe — nature / adventure / mountain ───────────────────────
    CatalogEntry("BGO", "Bergen", "Norway", "NO", "Europe",
        "fjords, hiking, nature, scenic train, salmon, dramatic landscapes",
        "Bergen is the gateway to the fjords — short flights or a scenic train and you're in serious nature.",
        16, 1, 140, 5),
    CatalogEntry("KEF", "Reykjavik", "Iceland", "IS", "Europe",
        "geothermal, northern lights, hiking, volcanoes, dramatic landscapes",
        "Reykjavik is the base for ring-road drives, hot springs and (winter) northern lights chasing.",
        13, 0, 170, 6),
    CatalogEntry("INN", "Innsbruck", "Austria", "AT", "Europe",
        "ski, snowboard, alps, hiking, mountain villages, après-ski",
        "Innsbruck puts an Alpine ski resort 20 minutes from the old town — winter focus, summer hiking.",
        21, -1, 130, 5),
    CatalogEntry("CMF", "Chambéry", "France", "FR", "Europe",
        "ski, alps, hiking, lakes, après-ski, winter weekends",
        "Chambéry is the practical hub for the French Alps — Courchevel and Val Thorens within a short transfer.",
        23, 2, 130, 5),

    # ── Europe — beach / sun ─────────────────────────────────────────
    CatalogEntry("MRS", "Marseille", "France", "FR", "Europe",
        "beach, calanques, mediterranean food, hiking, ferry to islands, harbour",
        "Marseille pairs harbour life with the Calanques — bouillabaisse, sea kayaking and short trains to Aix or Cassis.",
        29, 9, 100, 4),
    CatalogEntry("NAP", "Naples", "Italy", "IT", "Europe",
        "pizza, ancient history, coastal day trips, ferries to Capri, mount Vesuvius",
        "Naples is gritty and intense — best pizza in the world, Pompeii at hand, ferries to Procida and Capri.",
        29, 10, 80, 5),
    CatalogEntry("PMI", "Palma", "Spain", "ES", "Europe",
        "beach, mediterranean, hiking, cycling, food, family-friendly",
        "Palma de Mallorca handles beach + cycling + tramuntana hiking on the same trip — family- and couple-friendly.",
        29, 12, 110, 5),
    CatalogEntry("HER", "Heraklion", "Greece", "GR", "Europe",
        "beach, archaeology, Cretan food, mountain hikes, family friendly",
        "Crete's capital is the base for beaches, Knossos ruins and gorges — long days, Cretan tavernas at night.",
        30, 13, 90, 7),

    # ── Europe — short city break / quick weekend ────────────────────
    CatalogEntry("EDI", "Edinburgh", "United Kingdom", "GB", "Europe",
        "history, castles, festival, hiking, whisky, atmospheric old town",
        "Edinburgh is dramatic year-round — old town walks, castle, Arthur's Seat hike, whisky tasting in winter.",
        18, 4, 130, 3),
    CatalogEntry("DUB", "Dublin", "Ireland", "IE", "Europe",
        "literary, pubs, music, walking tours, day trips, friendly",
        "Dublin is pub-and-walking-tours — Guinness, Trinity Library, day trips to Cliffs of Moher.",
        18, 6, 120, 3),
    CatalogEntry("BUD", "Budapest", "Hungary", "HU", "Europe",
        "thermal baths, river cruises, ruin bars, affordable, history",
        "Budapest is the affordable wellness city — thermal baths every afternoon, ruin bars at night, Danube cruises.",
        25, 1, 65, 4),

    # ── Asia ─────────────────────────────────────────────────────────
    CatalogEntry("HND", "Tokyo", "Japan", "JP", "Asia",
        "neon, sushi, anime, technology, cherry blossom, shrines, food",
        "Tokyo is the dense city break — neighbourhoods feel like cities, ramen at midnight, day trips to Hakone.",
        29, 6, 140, 8),
    CatalogEntry("KIX", "Kyoto", "Japan", "JP", "Asia",
        "shrines, traditional, tea, gardens, geisha district, autumn colours",
        "Kyoto is the slow Japan — temples, kaiseki dinners, tea ceremonies, autumn foliage in November.",
        28, 5, 130, 5),
    CatalogEntry("BKK", "Bangkok", "Thailand", "TH", "Asia",
        "street food, temples, nightlife, markets, affordable, day trips",
        "Bangkok is the cheap, intense city break — street food, temples, river ferries and 1h flights to islands.",
        32, 26, 50, 5),
    CatalogEntry("SIN", "Singapore", "Singapore", "SG", "Asia",
        "food, gardens, modern architecture, family-friendly, multicultural, safe",
        "Singapore is the family-friendly hub — Gardens by the Bay, hawker centres, easy day-trip into Malaysia.",
        31, 26, 130, 4),
    CatalogEntry("DPS", "Bali", "Indonesia", "ID", "Asia",
        "beach, surf, yoga, temples, rice terraces, affordable, slow travel",
        "Bali splits between Ubud's rice terraces and beach towns — surf, yoga, temples, easy long stays.",
        30, 29, 50, 10),
    CatalogEntry("ICN", "Seoul", "South Korea", "KR", "Asia",
        "K-pop, food, palaces, shopping, technology, nightlife, hiking",
        "Seoul is youth-driven — palaces by day, BBQ + nightlife by night, mountain hikes within the city.",
        29, -2, 110, 5),
    CatalogEntry("HKG", "Hong Kong", "Hong Kong", "HK", "Asia",
        "skyline, food, dim sum, hiking, ferries, dense urban walks, finance hub",
        "Hong Kong is skyline + hiking — Victoria Peak, surprising trails, dim sum, ferries to Lantau.",
        30, 17, 130, 4),

    # ── Africa / Middle East ────────────────────────────────────────
    CatalogEntry("CAI", "Cairo", "Egypt", "EG", "Africa",
        "ancient egypt, pyramids, museums, Nile, history, affordable",
        "Cairo is pyramids + Nile — Giza at sunrise, Egyptian Museum, felucca rides, day trip to Saqqara.",
        34, 14, 60, 5),
    CatalogEntry("RAK", "Marrakech", "Morocco", "MA", "Africa",
        "souks, riads, atlas mountains, food, desert, affordable",
        "Marrakech is medina + desert — riads, souks, day-trips to the Atlas, longer trips into the Sahara.",
        32, 13, 70, 5),
    CatalogEntry("DXB", "Dubai", "United Arab Emirates", "AE", "Middle East",
        "skyscrapers, beaches, shopping, luxury, family-friendly, brunches",
        "Dubai is the luxury short break — Burj Khalifa, beaches, brunches, day-trip into the desert.",
        38, 19, 200, 4),

    # ── Americas ────────────────────────────────────────────────────
    CatalogEntry("JFK", "New York", "United States", "US", "North America",
        "city, museums, broadway, food, shopping, parks, nightlife",
        "New York City is the maximalist trip — Broadway, museums, dense food scene, Central Park, walkable boroughs.",
        27, 1, 200, 5),
    CatalogEntry("YUL", "Montréal", "Canada", "CA", "North America",
        "french-speaking, festivals, food, neighbourhoods, friendly, jazz",
        "Montréal is North America's francophone city — bagels, jazz festival, biking the Lachine canal.",
        25, -8, 130, 4),
    CatalogEntry("LAX", "Los Angeles", "United States", "US", "North America",
        "beach, road trips, hollywood, food, hiking, drive-everywhere",
        "Los Angeles needs a car — Malibu beaches, Griffith hike, Mexican food, day-trip to Joshua Tree.",
        25, 14, 180, 6),
    CatalogEntry("MEX", "Mexico City", "Mexico", "MX", "North America",
        "food, museums, neighbourhoods, mariachi, history, affordable, ruins nearby",
        "Mexico City is the food + museum mega-city — Roma + Condesa, Frida Kahlo, Teotihuacan day-trip.",
        24, 13, 80, 5),
    CatalogEntry("SCL", "Santiago", "Chile", "CL", "South America",
        "andes, wine, hiking, ski, day trips, food, Atacama gateway",
        "Santiago sits between Andes ski resorts and Pacific beaches — wine valleys, Atacama within reach by short flight.",
        28, 9, 90, 5),

    # ── Oceania ─────────────────────────────────────────────────────
    CatalogEntry("SYD", "Sydney", "Australia", "AU", "Oceania",
        "beach, harbour, hiking, surfing, opera, blue mountains, friendly",
        "Sydney is harbour + beaches — Bondi to Coogee walk, ferries to Manly, Blue Mountains day-trip.",
        25, 13, 170, 7),
]
# fmt: on


__all__ = ["CATALOG", "CatalogEntry"]
