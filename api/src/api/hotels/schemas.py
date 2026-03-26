"""Schemas pour la recherche d'hôtels Amadeus."""

from pydantic import BaseModel


class HotelListItemResponse(BaseModel):
    chainCode: str | None = None
    iataCode: str | None = None
    dupeId: int | None = None
    name: str | None = None
    hotelId: str
    geoCode: dict | None = None
    address: dict | None = None
    lastUpdate: str | None = None


class HotelListSearchResponse(BaseModel):
    data: list[HotelListItemResponse]


class HotelOfferPriceResponse(BaseModel):
    currency: str | None = None
    base: str | None = None
    total: str | None = None


class HotelOfferItemResponse(BaseModel):
    id: str | None = None
    checkInDate: str | None = None
    checkOutDate: str | None = None
    room: dict | None = None
    guests: dict | None = None
    price: HotelOfferPriceResponse | None = None


class HotelOfferResultResponse(BaseModel):
    type: str = "hotel-offers"
    hotel: dict
    available: bool = True
    offers: list[HotelOfferItemResponse] = []


class HotelOffersSearchResponse(BaseModel):
    data: list[HotelOfferResultResponse]
