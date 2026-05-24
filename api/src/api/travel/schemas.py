"""Schémas Pydantic pour les routes travel."""

from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field, field_validator

from ...integrations.amadeus.types import (
    Location,
)


class LocationSearchResult(BaseModel):
    """Résultat de recherche de locations."""

    locations: list[Location]
    count: int


# Flight schemas
class FlightOfferSearchQuery(BaseModel):
    """Requête de recherche d'offres de vols."""

    originLocationCode: str = Field(..., min_length=1)
    destinationLocationCode: str = Field(..., min_length=1)
    departureDate: str = Field(..., description="YYYY-MM-DD")
    adults: int = Field(..., ge=1, le=9)
    returnDate: str | None = Field(None, description="YYYY-MM-DD")
    children: int | None = Field(None, ge=0, le=9)
    infants: int | None = Field(None, ge=0, le=9)
    travelClass: Literal["ECONOMY", "PREMIUM_ECONOMY", "BUSINESS", "FIRST"] | None = None
    nonStop: bool | None = None
    currencyCode: str | None = Field(None, min_length=3, max_length=3)
    maxPrice: int | None = Field(None, gt=0)
    max: int | None = Field(None, ge=1, le=250)
    includedAirlineCodes: str | None = None
    excludedAirlineCodes: str | None = None

    @field_validator("departureDate", "returnDate")
    @classmethod
    def validate_date(cls, v: str | None) -> str | None:
        """Valide le format de date."""
        if v is None:
            return v
        try:
            datetime.strptime(v, "%Y-%m-%d")
            return v
        except ValueError as err:
            raise ValueError("Date must be in YYYY-MM-DD format") from err


class FlightDestinationSearchQuery(BaseModel):
    """Requête de recherche de destinations."""

    origin: str = Field(..., min_length=1)
    departureDate: str | None = Field(None, description="YYYY-MM-DD or range")
    oneWay: bool | None = None
    duration: int | None = Field(None, gt=0)
    nonStop: bool | None = None
    maxPrice: int | None = Field(None, gt=0)
    viewBy: Literal["DURATION", "COUNTRY", "DATE", "DESTINATION", "WEEK"] | None = None


class FlightCheapestDateSearchQuery(BaseModel):
    """Requête de recherche de dates les moins chères."""

    origin: str = Field(..., min_length=1)
    destination: str = Field(..., min_length=1)
    departureDate: str | None = Field(None, description="YYYY-MM-DD or range")
    oneWay: bool | None = None
    duration: int | None = Field(None, gt=0)
    nonStop: bool | None = None
    maxPrice: int | None = Field(None, gt=0)
    viewBy: Literal["DATE", "DURATION", "WEEK"] | None = None
