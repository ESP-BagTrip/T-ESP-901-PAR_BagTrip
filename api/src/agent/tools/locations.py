"""Outils LangChain pour la recherche de locations Amadeus."""

from langchain_core.tools import tool

from src.integrations.amadeus.locations import (
    search_location_by_id,
    search_location_nearest,
    search_locations_by_keyword,
)
from src.integrations.amadeus.types import (
    LocationIdSearchQuery,
    LocationKeywordSearchQuery,
    LocationNearestSearchQuery,
)


@tool
async def search_locations_by_keyword_tool(keyword: str, sub_type: list[str] | None = None) -> str:
    """
    Recherche des lieux (aéroports, villes) par mot-clé.
    Utilisez cet outil pour trouver des aéroports ou des villes quand l'utilisateur donne un nom de ville ou un code IATA.

    Args:
        keyword: Le mot-clé de recherche (ex: "Paris", "CDG", "London").
        sub_type: Filtre optionnel sur le type de lieu ["AIRPORT", "CITY"]. Par défaut cherche les deux.
    """
    if sub_type is None:
        sub_type = ["AIRPORT", "CITY"]

    # Conversion de la liste en chaîne séparée par des virgules pour l'API Amadeus
    sub_type_str = ",".join(sub_type) if isinstance(sub_type, list) else sub_type

    query = LocationKeywordSearchQuery(keyword=keyword, subType=sub_type_str)
    try:
        locations = await search_locations_by_keyword(query)
        return str([loc.model_dump() for loc in locations])
    except Exception as e:
        return f"Erreur lors de la recherche: {str(e)}"


@tool
async def search_location_by_id_tool(location_id: str) -> str:
    """
    Recherche une location spécifique par son identifiant Amadeus.

    Args:
        location_id: L'identifiant unique de la location (ex: "CMU").
    """
    query = LocationIdSearchQuery(id=location_id)
    try:
        location = await search_location_by_id(query)
        return str(location.model_dump())
    except Exception as e:
        return f"Erreur lors de la recherche par ID: {str(e)}"


@tool
async def search_location_nearest_tool(latitude: float, longitude: float, radius: int = 500) -> str:
    """
    Trouve les aéroports les plus proches d'une position géographique.

    Args:
        latitude: La latitude du point central.
        longitude: La longitude du point central.
        radius: Le rayon de recherche en kilomètres (défaut: 500).
    """
    query = LocationNearestSearchQuery(latitude=latitude, longitude=longitude, radius=radius)
    try:
        locations = await search_location_nearest(query)
        return str([loc.model_dump() for loc in locations])
    except Exception as e:
        return f"Erreur lors de la recherche de proximité: {str(e)}"
