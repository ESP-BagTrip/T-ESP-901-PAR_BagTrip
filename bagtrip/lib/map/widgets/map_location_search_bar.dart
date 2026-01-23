import 'dart:async';

import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/map/bloc/map_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MapLocationSearchBar extends StatefulWidget {
  const MapLocationSearchBar({super.key});

  @override
  State<MapLocationSearchBar> createState() => _MapLocationSearchBarState();
}

class _MapLocationSearchBarState extends State<MapLocationSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  bool _showResults = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (value.isNotEmpty) {
        context.read<MapBloc>().add(SearchLocations(value));
        setState(() {
          _showResults = true;
        });
      } else {
        context.read<MapBloc>().add(ClearSearch());
        setState(() {
          _showResults = false;
        });
      }
    });
  }

  void _onResultTap(Map<String, dynamic> location) {
    final geoCode = location['geoCode'] as Map<String, dynamic>?;
    if (geoCode != null) {
      final lat = geoCode['latitude'] as double?;
      final lng = geoCode['longitude'] as double?;
      if (lat != null && lng != null) {
        context.read<MapBloc>().add(NavigateToLocation(
          latitude: lat,
          longitude: lng,
          zoom: 12.0,
        ));
      }
    }

    _controller.clear();
    _focusNode.unfocus();
    setState(() {
      _showResults = false;
    });
    context.read<MapBloc>().add(ClearSearch());
  }

  void _clearSearch() {
    _controller.clear();
    context.read<MapBloc>().add(ClearSearch());
    setState(() {
      _showResults = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MapBloc, MapState>(
      builder: (context, state) {
        final searchResults = state is MapLoaded ? state.searchResults : <Map<String, dynamic>>[];

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search field
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.medium8,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search cities or airports...',
                  prefixIcon: const Icon(Icons.search, color: ColorName.primary),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: _clearSearch,
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: AppSpacing.allEdgeInsetSpace16,
                ),
              ),
            ),

            // Search results dropdown
            if (_showResults && searchResults.isNotEmpty)
              Container(
                margin: AppSpacing.onlyTopSpace8,
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppRadius.medium8,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: searchResults.length,
                  itemBuilder: (context, index) {
                    final location = searchResults[index];
                    return _SearchResultTile(
                      location: location,
                      onTap: () => _onResultTap(location),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final Map<String, dynamic> location;
  final VoidCallback onTap;

  const _SearchResultTile({
    required this.location,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final subType = location['subType']?.toString().toUpperCase() ?? '';
    final isAirport = subType == 'AIRPORT';
    final name = location['name']?.toString() ?? 'Unknown';
    final iataCode = location['iataCode']?.toString();
    final city = location['city']?.toString() ?? location['cityName']?.toString();
    final countryCode = location['countryCode']?.toString();

    return ListTile(
      leading: Icon(
        isAirport ? Icons.local_airport : Icons.location_city,
        color: isAirport ? ColorName.primary : ColorName.secondary,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          if (iataCode != null && iataCode.isNotEmpty)
            Container(
              margin: AppSpacing.onlyLeftSpace8,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: ColorName.primary.withValues(alpha: 0.1),
                borderRadius: AppRadius.small4,
              ),
              child: Text(
                iataCode,
                style: const TextStyle(
                  color: ColorName.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
      subtitle: city != null || countryCode != null
          ? Text(
              [city, countryCode].where((e) => e != null).join(', '),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            )
          : null,
      onTap: onTap,
    );
  }
}
