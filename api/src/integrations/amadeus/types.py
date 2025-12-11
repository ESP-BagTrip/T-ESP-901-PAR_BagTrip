"""Types Pydantic pour les intégrations Amadeus."""

from typing import Literal

from pydantic import BaseModel, Field

# ============================================================================
# LOCATION TYPES
# ============================================================================


class LocationKeywordSearchQuery(BaseModel):
    """Requête de recherche de location par mot-clé."""

    subType: str = Field(..., description="CITY,AIRPORT")
    keyword: str = Field(..., description="Search keyword like 'paris'")


class LocationIdSearchQuery(BaseModel):
    """Requête de recherche de location par ID."""

    id: str


class LocationNearestSearchQuery(BaseModel):
    """Requête de recherche de location la plus proche."""

    latitude: float
    longitude: float


class LocationSelf(BaseModel):
    """Lien self pour une location."""

    href: str
    methods: list[str]

    class Config:
        populate_by_name = True


class LocationGeoCode(BaseModel):
    """Coordonnées géographiques."""

    latitude: float
    longitude: float


class LocationAddress(BaseModel):
    """Adresse d'une location."""

    cityName: str
    cityCode: str
    countryName: str
    countryCode: str
    regionCode: str


class LocationAnalytics(BaseModel):
    """Analytics d'une location."""

    travelers: dict[str, float]


class Location(BaseModel):
    """Modèle de location Amadeus."""

    type: str
    subType: str
    name: str
    detailedName: str
    id: str
    self_: LocationSelf = Field(..., alias="self")
    timeZoneOffset: str
    iataCode: str | None = None
    geoCode: LocationGeoCode
    address: LocationAddress
    analytics: LocationAnalytics | None = None

    class Config:
        populate_by_name = True


# ============================================================================
# FLIGHT TYPES
# ============================================================================


class FlightOfferSearchQuery(BaseModel):
    """Requête de recherche d'offres de vols."""

    originLocationCode: str
    destinationLocationCode: str
    departureDate: str = Field(..., description="YYYY-MM-DD")
    adults: int
    returnDate: str | None = Field(None, description="YYYY-MM-DD")
    children: int | None = None
    infants: int | None = None
    travelClass: Literal["ECONOMY", "PREMIUM_ECONOMY", "BUSINESS", "FIRST"] | None = None
    nonStop: bool | None = None
    currencyCode: str | None = None
    maxPrice: int | None = None
    max: int | None = None
    includedAirlineCodes: str | None = Field(None, description="Comma-separated airline codes")
    excludedAirlineCodes: str | None = Field(None, description="Comma-separated airline codes")


class FlightEndpoint(BaseModel):
    """Point de départ/arrivée d'un vol."""

    iataCode: str
    at: str
    terminal: str | None = None


class FlightAircraft(BaseModel):
    """Aéronef."""

    code: str


class FlightOperating(BaseModel):
    """Compagnie opérante."""

    carrierCode: str


class FlightSegment(BaseModel):
    """Segment de vol."""

    departure: FlightEndpoint
    arrival: FlightEndpoint
    carrierCode: str
    number: str
    aircraft: FlightAircraft | None = None
    operating: FlightOperating | None = None
    duration: str
    id: str
    numberOfStops: int
    blacklistedInEU: bool


class FlightItinerary(BaseModel):
    """Itinéraire de vol."""

    duration: str
    segments: list[FlightSegment]


class FlightFee(BaseModel):
    """Frais."""

    amount: str
    type: str


class FlightAdditionalService(BaseModel):
    """Service additionnel."""

    amount: str
    type: str


class FlightPrice(BaseModel):
    """Prix d'un vol."""

    currency: str
    total: str
    base: str
    fees: list[FlightFee] | None = None
    grandTotal: str
    additionalServices: list[FlightAdditionalService] | None = None


class FlightPricingOptions(BaseModel):
    """Options de tarification."""

    fareType: list[str]
    includedCheckedBagsOnly: bool


class TravelerPrice(BaseModel):
    """Prix pour un voyageur."""

    currency: str
    total: str
    base: str


class IncludedCheckedBags(BaseModel):
    """Bagages enregistrés inclus."""

    quantity: int


class FareDetailsBySegment(BaseModel):
    """Détails de tarif par segment."""

    segmentId: str
    cabin: str
    fareBasis: str
    class_: str = Field(..., alias="class")
    includedCheckedBags: IncludedCheckedBags | None = None

    class Config:
        populate_by_name = True


class TravelerPricing(BaseModel):
    """Tarification pour un voyageur."""

    travelerId: str
    fareOption: str
    travelerType: str
    price: TravelerPrice
    fareDetailsBySegment: list[FareDetailsBySegment]


class FlightOffer(BaseModel):
    """Offre de vol."""

    type: str
    id: str
    source: str
    instantTicketingRequired: bool
    nonHomogeneous: bool
    oneWay: bool
    isUpsellOffer: bool
    lastTicketingDate: str | None = None
    lastTicketingDateTime: str | None = None
    numberOfBookableSeats: int | None = None
    itineraries: list[FlightItinerary]
    price: FlightPrice
    pricingOptions: FlightPricingOptions
    validatingAirlineCodes: list[str]
    travelerPricings: list[TravelerPricing]


class FlightOfferMetaLinks(BaseModel):
    """Liens de métadonnées."""

    self_: str = Field(..., alias="self")

    class Config:
        populate_by_name = True


class FlightOfferMeta(BaseModel):
    """Métadonnées de réponse."""

    count: int
    links: FlightOfferMetaLinks


class FlightOfferDictionaries(BaseModel):
    """Dictionnaires de référence."""

    locations: dict[str, dict[str, str]] | None = None
    aircraft: dict[str, str] | None = None
    currencies: dict[str, str] | None = None
    carriers: dict[str, str] | None = None


class FlightOfferResponse(BaseModel):
    """Réponse de recherche d'offres de vols."""

    meta: FlightOfferMeta
    data: list[FlightOffer]
    dictionaries: FlightOfferDictionaries | None = None


# Flight Inspiration Search (Destinations)
class FlightInspirationSearchQuery(BaseModel):
    """Requête de recherche de destinations inspirantes."""

    origin: str = Field(..., description="IATA code")
    departureDate: str | None = Field(
        None, description="YYYY-MM-DD or YYYY-MM-DD,YYYY-MM-DD for range"
    )
    oneWay: bool | None = None
    duration: int | None = Field(None, description="in days")
    nonStop: bool | None = None
    maxPrice: int | None = None
    viewBy: Literal["DURATION", "COUNTRY", "DATE", "DESTINATION", "WEEK"] | None = None


class FlightDestinationPrice(BaseModel):
    """Prix d'une destination."""

    total: str


class FlightDestinationLinks(BaseModel):
    """Liens d'une destination."""

    flightDates: str | None = None
    flightOffers: str | None = None


class FlightDestination(BaseModel):
    """Destination de vol."""

    type: str
    origin: str
    destination: str
    departureDate: str
    returnDate: str | None = None
    price: FlightDestinationPrice
    links: FlightDestinationLinks | None = None


class FlightDestinationMetaLinks(BaseModel):
    """Liens de métadonnées de destination."""

    self_: str | None = Field(None, alias="self")

    class Config:
        populate_by_name = True


class FlightDestinationMeta(BaseModel):
    """Métadonnées de réponse de destination."""

    currency: str
    links: FlightDestinationMetaLinks | None = None


class FlightDestinationResponse(BaseModel):
    """Réponse de recherche de destinations."""

    meta: FlightDestinationMeta
    data: list[FlightDestination]


# Flight Cheapest Date Search
class FlightCheapestDateSearchQuery(BaseModel):
    """Requête de recherche de dates les moins chères."""

    origin: str
    destination: str
    departureDate: str | None = Field(
        None, description="YYYY-MM-DD or YYYY-MM-DD,YYYY-MM-DD for range"
    )
    oneWay: bool | None = None
    duration: int | None = Field(None, description="in days")
    nonStop: bool | None = None
    maxPrice: int | None = None
    viewBy: Literal["DATE", "DURATION", "WEEK"] | None = None


class FlightDatePrice(BaseModel):
    """Prix d'une date."""

    total: str


class FlightDateLinks(BaseModel):
    """Liens d'une date."""

    flightDestinations: str | None = None
    flightOffers: str | None = None


class FlightDate(BaseModel):
    """Date de vol."""

    type: str
    origin: str
    destination: str
    departureDate: str
    returnDate: str | None = None
    price: FlightDatePrice
    links: FlightDateLinks | None = None


class FlightDateMetaLinks(BaseModel):
    """Liens de métadonnées de date."""

    self_: str | None = Field(None, alias="self")

    class Config:
        populate_by_name = True


class FlightDateMeta(BaseModel):
    """Métadonnées de réponse de date."""

    currency: str
    links: FlightDateMetaLinks | None = None


class FlightDateResponse(BaseModel):
    """Réponse de recherche de dates les moins chères."""

    meta: FlightDateMeta
    data: list[FlightDate]
