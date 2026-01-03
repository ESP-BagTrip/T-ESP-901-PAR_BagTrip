import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/flightResultDetails/widgets/baggage_info_card.dart';
import 'package:bagtrip/flightResultDetails/widgets/class_info_card.dart';
import 'package:bagtrip/flightResultDetails/widgets/fare_info_card.dart';
import 'package:bagtrip/flightResultDetails/widgets/flight_detail_card.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';

class FlightResultDetailsView extends StatelessWidget {
  const FlightResultDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: ColorName.secondary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Sélectionnez votre tarif',
          style: TextStyle(
            fontFamily: FontFamily.b612,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: ColorName.primary,
          ),
        ),
        centerTitle: true,
      ),
      body: const SingleChildScrollView(
        padding: AppSpacing.allEdgeInsetSpace16,
        child: Column(
          children: [
            // Outbound Flight
            FlightDetailCard(
              title: 'Vol aller',
              icon: Icons.flight_takeoff,
              date: 'Lundi 2 septembre',
              departureTime: '15:55',
              departureAirport: 'CDG T2F',
              arrivalTime: '16:55',
              arrivalAirport: 'FCO T1',
              duration: '1h00',
              airline: 'Air France',
              aircraft: 'Airbus A321',
              tagLabel: 'Vol direct',
            ),
            SizedBox(height: 16),
            // Return Flight
            FlightDetailCard(
              title: 'Vol retour',
              icon: Icons.flight_land, // Or flip icon
              date: 'Mardi 9 octobre',
              departureTime: '15:55',
              departureAirport: 'FCO T1',
              arrivalTime: '16:55',
              arrivalAirport: 'CDG T2F',
              duration: '1h00',
              airline: 'Air France',
              aircraft: 'Airbus A321',
              tagLabel: '1 escale',
              tagColor: Colors.orange, // Specific color from screenshot
            ),
            SizedBox(height: 16),
            // Baggage Info
            BaggageInfoCard(),
            SizedBox(height: 16),
            // Class Info
            ClassInfoCard(),
            SizedBox(height: 16),
            // Fare Info
            FareInfoCard(),
            SizedBox(height: 32), // Bottom padding
          ],
        ),
      ),
    );
  }
}
