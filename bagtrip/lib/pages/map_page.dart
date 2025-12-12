import 'package:flutter/material.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/design/tokens.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: AppSpacing.allEdgeInsetSpace24,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.map_outlined,
                size: 80,
                color: ColorName.secondary,
              ),
              const SizedBox(height: AppSpacing.space16),
              Text(
                'Visualiser les destinations',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.space8),
              Text(
                'Explorez les destinations disponibles sur une carte interactive',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ColorName.primaryTrueDark.withValues(alpha: 0.7),
                    ),
              ),
              const SizedBox(height: AppSpacing.space32),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.location_on_outlined),
                label: const Text('Commencer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
