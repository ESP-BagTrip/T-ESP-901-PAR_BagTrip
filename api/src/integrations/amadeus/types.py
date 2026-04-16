"""Types Pydantic pour les intégrations Amadeus."""

from typing import Literal

from pydantic import BaseModel, ConfigDict, Field

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

    model_config = ConfigDict(populate_by_name=True)


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

    model_config = ConfigDict(populate_by_name=True)


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

    carrierCode: str | None = None
    carrierName: str | None = None


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
    blacklistedInEU: bool | None = None


class FlightItinerary(BaseModel):
    """Itinéraire de vol."""

    duration: str | None = None
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

    quantity: int | None = None
    weight: int | None = None
    weightUnit: str | None = None


class IncludedCabinBags(BaseModel):
    """Bagages cabine inclus."""

    quantity: int | None = None
    weight: int | None = None
    weightUnit: str | None = None


class FareDetailsBySegment(BaseModel):
    """Détails de tarif par segment."""

    segmentId: str
    cabin: str
    fareBasis: str
    class_: str = Field(..., alias="class")
    includedCheckedBags: IncludedCheckedBags | None = None
    includedCabinBags: IncludedCabinBags | None = None

    model_config = ConfigDict(populate_by_name=True)


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
    oneWay: bool | None = None
    isUpsellOffer: bool | None = None
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

    model_config = ConfigDict(populate_by_name=True)


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

    model_config = ConfigDict(populate_by_name=True)


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

    model_config = ConfigDict(populate_by_name=True)


class FlightDateMeta(BaseModel):
    """Métadonnées de réponse de date."""

    currency: str
    links: FlightDateMetaLinks | None = None


class FlightDateResponse(BaseModel):
    """Réponse de recherche de dates les moins chères."""

    meta: FlightDateMeta
    data: list[FlightDate]


# ============================================================================
# FLIGHT PRICING TYPES
# ============================================================================


class FlightPriceQuery(BaseModel):
    """Requête de vérification de prix."""

    data: dict[str, str | list[FlightOffer]]


class FlightPriceResponse(BaseModel):
    """Réponse de vérification de prix."""

    data: dict[str, list[FlightOffer]]


# ============================================================================
# FLIGHT ORDER TYPES
# ============================================================================


class FlightTravelerName(BaseModel):
    """Nom du voyageur."""

    firstName: str
    lastName: str


class FlightTravelerPhone(BaseModel):
    """Téléphone du voyageur."""

    deviceType: str = "MOBILE"
    countryCallingCode: str
    number: str


class FlightTravelerContact(BaseModel):
    """Contact du voyageur."""

    emailAddress: str | None = None
    phones: list[FlightTravelerPhone]


class FlightTravelerDocument(BaseModel):
    """Document du voyageur."""

    documentType: str = "PASSPORT"  # PASSPORT, IDENTITY_CARD, VISA, etc.
    birthPlace: str | None = None
    issuanceLocation: str | None = None
    issuanceDate: str | None = None  # YYYY-MM-DD
    number: str
    expiryDate: str  # YYYY-MM-DD
    issuanceCountry: str
    validityCountry: str
    nationality: str
    holder: bool = True


class FlightOrderTraveler(BaseModel):
    """Voyageur pour la création de commande."""

    id: str
    dateOfBirth: str  # YYYY-MM-DD
    name: FlightTravelerName
    gender: Literal["MALE", "FEMALE"]
    contact: FlightTravelerContact
    documents: list[FlightTravelerDocument] | None = None


class FlightOrderCreateQuery(BaseModel):
    """Requête de création de commande."""

    data: dict[str, str | list[FlightOffer] | list[FlightOrderTraveler]]


class FlightOrderResponse(BaseModel):
    """Réponse de création de commande."""

    data: dict


# ============================================================================
# HOTEL TYPES
# ============================================================================


class HotelListSearchQuery(BaseModel):
    """Requête de recherche d'hôtels par ville."""

    cityCode: str = Field(..., description="IATA city code (e.g. PAR)")
    radius: int | None = None
    radiusUnit: Literal["KM", "MILE"] | None = None
    ratings: str | None = Field(None, description="Comma-separated star ratings, e.g. '3,4,5'")
    hotelSource: Literal["ALL", "BEDBANK", "DIRECTCHAIN"] | None = None


class HotelGeoCode(BaseModel):
    """Coordonnées géographiques d'un hôtel."""

    latitude: float
    longitude: float


class HotelAddress(BaseModel):
    """Adresse d'un hôtel."""

    countryCode: str | None = None


class HotelListItem(BaseModel):
    """Hôtel trouvé via Hotel List API."""

    chainCode: str | None = None
    iataCode: str | None = None
    dupeId: int | None = None
    name: str | None = None
    hotelId: str
    geoCode: HotelGeoCode | None = None
    address: HotelAddress | None = None
    lastUpdate: str | None = None


class HotelListResponse(BaseModel):
    """Réponse de recherche d'hôtels par ville."""

    data: list[HotelListItem]


class HotelOffersSearchQuery(BaseModel):
    """Requête de recherche d'offres d'hôtels."""

    hotelIds: str = Field(..., description="Comma-separated hotel IDs (max 50)")
    adults: int | None = 1
    checkInDate: str | None = Field(None, description="YYYY-MM-DD")
    checkOutDate: str | None = Field(None, description="YYYY-MM-DD")
    currency: str | None = None


class HotelOfferPrice(BaseModel):
    """Prix d'une offre d'hôtel."""

    currency: str | None = None
    base: str | None = None
    total: str | None = None


class HotelOffer(BaseModel):
    """Offre d'hôtel."""

    id: str | None = None
    checkInDate: str | None = None
    checkOutDate: str | None = None
    room: dict | None = None
    guests: dict | None = None
    price: HotelOfferPrice | None = None


class HotelOfferResult(BaseModel):
    """Résultat d'une recherche d'offres d'hôtel."""

    type: str = "hotel-offers"
    hotel: dict
    available: bool = True
    offers: list[HotelOffer] = []


class HotelOffersResponse(BaseModel):
    """Réponse de recherche d'offres d'hôtels."""

    data: list[HotelOfferResult]
