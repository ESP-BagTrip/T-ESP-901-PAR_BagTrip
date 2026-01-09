"""Unit tests for agent location tools."""

from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from src.agent.tools.locations import (
    search_location_by_id_tool,
    search_location_nearest_tool,
    search_locations_by_keyword_tool,
)


@patch("src.agent.tools.locations.search_locations_by_keyword")
@pytest.mark.asyncio
async def test_search_locations_by_keyword_tool_success(mock_search):
    """Test successful keyword search tool."""
    mock_location = MagicMock()
    mock_location.model_dump.return_value = {"id": "PAR", "name": "Paris"}
    mock_search.return_value = [mock_location]

    result = await search_locations_by_keyword_tool.ainvoke({"keyword": "Paris"})
    
    assert "Paris" in result
    assert "PAR" in result
    mock_search.assert_called_once()


@patch("src.agent.tools.locations.search_locations_by_keyword")
@pytest.mark.asyncio
async def test_search_locations_by_keyword_tool_default_subtype(mock_search):
    """Test keyword search with default subtype."""
    mock_search.return_value = []
    
    await search_locations_by_keyword_tool.ainvoke({"keyword": "Paris"})
    
    # Check that search was called with default subtypes
    args, _ = mock_search.call_args
    query = args[0]
    assert query.subType == "AIRPORT,CITY"


@patch("src.agent.tools.locations.search_locations_by_keyword")
@pytest.mark.asyncio
async def test_search_locations_by_keyword_tool_custom_subtype(mock_search):
    """Test keyword search with custom subtype."""
    mock_search.return_value = []
    
    await search_locations_by_keyword_tool.ainvoke({"keyword": "Paris", "sub_type": ["CITY"]})
    
    args, _ = mock_search.call_args
    query = args[0]
    assert query.subType == "CITY"


@patch("src.agent.tools.locations.search_locations_by_keyword")
@pytest.mark.asyncio
async def test_search_locations_by_keyword_tool_error(mock_search):
    """Test keyword search error handling."""
    mock_search.side_effect = Exception("Amadeus Error")
    
    result = await search_locations_by_keyword_tool.ainvoke({"keyword": "Paris"})
    
    assert "Erreur lors de la recherche" in result
    assert "Amadeus Error" in result


@patch("src.agent.tools.locations.search_location_by_id")
@pytest.mark.asyncio
async def test_search_location_by_id_tool_success(mock_search):
    """Test successful ID search tool."""
    mock_location = MagicMock()
    mock_location.model_dump.return_value = {"id": "CDG", "name": "Charles de Gaulle"}
    mock_search.return_value = mock_location
    
    result = await search_location_by_id_tool.ainvoke({"location_id": "CDG"})
    
    assert "CDG" in result
    assert "Charles de Gaulle" in result
    mock_search.assert_called_once()


@patch("src.agent.tools.locations.search_location_by_id")
@pytest.mark.asyncio
async def test_search_location_by_id_tool_error(mock_search):
    """Test ID search error handling."""
    mock_search.side_effect = Exception("Not Found")
    
    result = await search_location_by_id_tool.ainvoke({"location_id": "UNKNOWN"})
    
    assert "Erreur lors de la recherche par ID" in result
    assert "Not Found" in result


@patch("src.agent.tools.locations.search_location_nearest")
@pytest.mark.asyncio
async def test_search_location_nearest_tool_success(mock_search):
    """Test successful nearest location search tool."""
    mock_location = MagicMock()
    mock_location.model_dump.return_value = {"id": "LHR", "name": "London Heathrow"}
    mock_search.return_value = [mock_location]
    
    result = await search_location_nearest_tool.ainvoke({"latitude": 51.5, "longitude": -0.45})
    
    assert "LHR" in result
    mock_search.assert_called_once()


@patch("src.agent.tools.locations.search_location_nearest")
@pytest.mark.asyncio
async def test_search_location_nearest_tool_error(mock_search):
    """Test nearest location search error handling."""
    mock_search.side_effect = Exception("Geo Error")
    
    result = await search_location_nearest_tool.ainvoke({"latitude": 0, "longitude": 0})
    
    assert "Erreur lors de la recherche de proximité" in result
    assert "Geo Error" in result
