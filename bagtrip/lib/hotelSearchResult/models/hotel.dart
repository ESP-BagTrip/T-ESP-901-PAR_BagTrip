/// Modèle représentant un hôtel reçu de l'API
/// 
/// Basé sur HotelOffer du backend (api/src/models/hotel_offer.py)
class Hotel {
  final String id;           // UUID de l'offre
  final String? hotelId;     // ID de l'hôtel Amadeus
  final String? name;        // Nom de l'hôtel (à extraire de offer_json)
  final String? roomType;    // Type de chambre
  final double? totalPrice;  // Prix total
  final String? currency;    // Devise (EUR, USD...)
  final String? chainCode;   // Code de la chaîne hôtelière

  Hotel({
    required this.id,
    this.hotelId,
    this.name,
    this.roomType,
    this.totalPrice,
    this.currency,
    this.chainCode,
  });

  /// Crée un Hotel depuis la réponse JSON de l'API
  factory Hotel.fromJson(Map<String, dynamic> json) {
    return Hotel(
      id: json['id'] ?? '',
      hotelId: json['hotel_id'],
      name: json['name'] ?? json['offer_json']?['hotel']?['name'],
      roomType: json['room_type'],
      totalPrice: json['total_price'] != null 
          ? double.tryParse(json['total_price'].toString()) 
          : null,
      currency: json['currency'],
      chainCode: json['chain_code'],
    );
  }

  /// Affiche le prix formaté (ex: "150.00 EUR")
  String get formattedPrice {
    if (totalPrice == null) return 'Prix non disponible';
    return '${totalPrice!.toStringAsFixed(2)} ${currency ?? ''}';
  }
}