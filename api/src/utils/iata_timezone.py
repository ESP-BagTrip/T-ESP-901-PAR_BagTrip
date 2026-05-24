"""IATA airport code to IANA timezone mapping."""

IATA_TIMEZONE_MAP: dict[str, str] = {
    # France
    "CDG": "Europe/Paris",
    "ORY": "Europe/Paris",
    "LYS": "Europe/Paris",
    "NCE": "Europe/Paris",
    "MRS": "Europe/Paris",
    "TLS": "Europe/Paris",
    "BOD": "Europe/Paris",
    "NTE": "Europe/Paris",
    # UK
    "LHR": "Europe/London",
    "LGW": "Europe/London",
    "STN": "Europe/London",
    "LTN": "Europe/London",
    "MAN": "Europe/London",
    "EDI": "Europe/London",
    # Germany
    "FRA": "Europe/Berlin",
    "MUC": "Europe/Berlin",
    "BER": "Europe/Berlin",
    "DUS": "Europe/Berlin",
    "HAM": "Europe/Berlin",
    # Spain
    "MAD": "Europe/Madrid",
    "BCN": "Europe/Madrid",
    "PMI": "Europe/Madrid",
    "AGP": "Europe/Madrid",
    "ALC": "Europe/Madrid",
    "IBZ": "Europe/Madrid",
    "TFS": "Atlantic/Canary",
    "LPA": "Atlantic/Canary",
    # Italy
    "FCO": "Europe/Rome",
    "MXP": "Europe/Rome",
    "VCE": "Europe/Rome",
    "NAP": "Europe/Rome",
    "BGY": "Europe/Rome",
    # Netherlands
    "AMS": "Europe/Amsterdam",
    # Belgium
    "BRU": "Europe/Brussels",
    # Portugal
    "LIS": "Europe/Lisbon",
    "OPO": "Europe/Lisbon",
    "FAO": "Europe/Lisbon",
    # Switzerland
    "ZRH": "Europe/Zurich",
    "GVA": "Europe/Zurich",
    # Austria
    "VIE": "Europe/Vienna",
    # Greece
    "ATH": "Europe/Athens",
    "SKG": "Europe/Athens",
    "HER": "Europe/Athens",
    "JTR": "Europe/Athens",
    # Turkey
    "IST": "Europe/Istanbul",
    "SAW": "Europe/Istanbul",
    "AYT": "Europe/Istanbul",
    # Scandinavia
    "CPH": "Europe/Copenhagen",
    "ARN": "Europe/Stockholm",
    "OSL": "Europe/Oslo",
    "HEL": "Europe/Helsinki",
    # Eastern Europe
    "WAW": "Europe/Warsaw",
    "PRG": "Europe/Prague",
    "BUD": "Europe/Budapest",
    "OTP": "Europe/Bucharest",
    # Ireland
    "DUB": "Europe/Dublin",
    # Russia
    "SVO": "Europe/Moscow",
    "DME": "Europe/Moscow",
    "LED": "Europe/Moscow",
    # USA — East
    "JFK": "America/New_York",
    "EWR": "America/New_York",
    "LGA": "America/New_York",
    "BOS": "America/New_York",
    "PHL": "America/New_York",
    "IAD": "America/New_York",
    "DCA": "America/New_York",
    "MIA": "America/New_York",
    "FLL": "America/New_York",
    "MCO": "America/New_York",
    "ATL": "America/New_York",
    "CLT": "America/New_York",
    # USA — Central
    "ORD": "America/Chicago",
    "DFW": "America/Chicago",
    "IAH": "America/Chicago",
    "MSP": "America/Chicago",
    "DTW": "America/Detroit",
    # USA — Mountain
    "DEN": "America/Denver",
    "PHX": "America/Phoenix",
    "SLC": "America/Denver",
    # USA — West
    "LAX": "America/Los_Angeles",
    "SFO": "America/Los_Angeles",
    "SEA": "America/Los_Angeles",
    "SAN": "America/Los_Angeles",
    "LAS": "America/Los_Angeles",
    "PDX": "America/Los_Angeles",
    # USA — Hawaii / Alaska
    "HNL": "Pacific/Honolulu",
    "ANC": "America/Anchorage",
    # Canada
    "YYZ": "America/Toronto",
    "YUL": "America/Montreal",
    "YVR": "America/Vancouver",
    "YYC": "America/Edmonton",
    # Mexico
    "MEX": "America/Mexico_City",
    "CUN": "America/Cancun",
    # Caribbean
    "SJU": "America/Puerto_Rico",
    "PUJ": "America/Santo_Domingo",
    # South America
    "GRU": "America/Sao_Paulo",
    "GIG": "America/Sao_Paulo",
    "EZE": "America/Argentina/Buenos_Aires",
    "BOG": "America/Bogota",
    "SCL": "America/Santiago",
    "LIM": "America/Lima",
    # Middle East
    "DXB": "Asia/Dubai",
    "AUH": "Asia/Dubai",
    "DOH": "Asia/Qatar",
    "RUH": "Asia/Riyadh",
    "JED": "Asia/Riyadh",
    "TLV": "Asia/Jerusalem",
    "AMM": "Asia/Amman",
    # South Asia
    "DEL": "Asia/Kolkata",
    "BOM": "Asia/Kolkata",
    "BLR": "Asia/Kolkata",
    "MAA": "Asia/Kolkata",
    "CMB": "Asia/Colombo",
    # Southeast Asia
    "SIN": "Asia/Singapore",
    "BKK": "Asia/Bangkok",
    "KUL": "Asia/Kuala_Lumpur",
    "CGK": "Asia/Jakarta",
    "HAN": "Asia/Ho_Chi_Minh",
    "SGN": "Asia/Ho_Chi_Minh",
    "MNL": "Asia/Manila",
    "DPS": "Asia/Makassar",
    # East Asia
    "NRT": "Asia/Tokyo",
    "HND": "Asia/Tokyo",
    "KIX": "Asia/Tokyo",
    "ICN": "Asia/Seoul",
    "GMP": "Asia/Seoul",
    "PEK": "Asia/Shanghai",
    "PVG": "Asia/Shanghai",
    "HKG": "Asia/Hong_Kong",
    "TPE": "Asia/Taipei",
    # Oceania
    "SYD": "Australia/Sydney",
    "MEL": "Australia/Melbourne",
    "BNE": "Australia/Brisbane",
    "PER": "Australia/Perth",
    "AKL": "Pacific/Auckland",
    # Africa
    "JNB": "Africa/Johannesburg",
    "CPT": "Africa/Johannesburg",
    "CAI": "Africa/Cairo",
    "CMN": "Africa/Casablanca",
    "NBO": "Africa/Nairobi",
    "ADD": "Africa/Addis_Ababa",
    "LOS": "Africa/Lagos",
    "ACC": "Africa/Accra",
    "DSS": "Africa/Dakar",
    "TUN": "Africa/Tunis",
    "ALG": "Africa/Algiers",
    "MRU": "Indian/Mauritius",
    # City codes (multi-airport)
    "PAR": "Europe/Paris",
    "LON": "Europe/London",
    "NYC": "America/New_York",
    "WAS": "America/New_York",
    "TYO": "Asia/Tokyo",
    "SEL": "Asia/Seoul",
    "BJS": "Asia/Shanghai",
    "MOW": "Europe/Moscow",
    "BUE": "America/Argentina/Buenos_Aires",
    "SAO": "America/Sao_Paulo",
    "RIO": "America/Sao_Paulo",
    "MIL": "Europe/Rome",
    "ROM": "Europe/Rome",
}


def resolve_timezone_from_iata(iata_code: str | None) -> str | None:
    """Resolve IATA airport/city code to IANA timezone string.

    Returns None if the code is unknown.
    """
    if not iata_code:
        return None
    return IATA_TIMEZONE_MAP.get(iata_code.upper())
