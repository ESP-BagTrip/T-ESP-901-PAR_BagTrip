import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../gen/colors.gen.dart';
import '../bloc/home_flight_bloc.dart';
import '../models/airport_type.dart';

class AirportSearchField extends StatefulWidget {
  final AirportType type;
  final String? hintText;
  final void Function(Map<String, dynamic>?, AirportType)? onSelected;

  const AirportSearchField({
    super.key,
    required this.type,
    this.hintText,
    this.onSelected,
  });

  @override
  State<AirportSearchField> createState() => _AirportSearchFieldState();
}

class _AirportSearchFieldState extends State<AirportSearchField> {
  final TextEditingController _controller = TextEditingController();
  final LayerLink _layerLink = LayerLink();
  bool _showResults = false;
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _controller.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOverlay(BuildContext context, List<Map<String, dynamic>> airports) {
    _removeOverlay();

    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            width: size.width,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0, size.height + 4),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shrinkWrap: true,
                    itemCount: airports.length,
                    separatorBuilder:
                        (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final airport = airports[index];
                      return ListTile(
                        dense: true,
                        title: Text(
                          airport['name'] ?? '',
                          style: const TextStyle(fontSize: 13),
                        ),
                        subtitle: Text(
                          '${airport['city'] ?? ''}, ${airport['countryCode'] ?? ''}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        onTap: () {
                          _controller.text = airport['name'] ?? '';
                          _removeOverlay();
                          setState(() => _showResults = false);
                          if (widget.onSelected != null) {
                            widget.onSelected!(airport, widget.type);
                          }
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: BlocConsumer<HomeFlightBloc, HomeFlightState>(
        listener: (context, state) {
          if (state is HomeFlightLoaded &&
              state.searchResults != null &&
              _showResults) {
            _showOverlay(context, state.searchResults ?? []);
          } else {
            _removeOverlay();
          }
        },
        builder: (context, state) {
          return TextField(
            // need to align text vertical center
            textAlignVertical: TextAlignVertical.center,
            controller: _controller,
            style: const TextStyle(fontFamily: FontFamily.b612, fontSize: 13),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: const TextStyle(
                fontSize: 13,
                color: ColorName.primary,
              ),
              border: InputBorder.none,
              isDense: true,
              suffixIcon:
                  _controller.text.isNotEmpty
                      ? IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _controller.clear();
                          _removeOverlay();
                          setState(() => _showResults = false);
                        },
                      )
                      : null,
            ),
            onChanged: (value) {
              setState(() => _showResults = value.isNotEmpty);
              if (value.length >= 2) {
                if (widget.type == AirportType.departure) {
                  context.read<HomeFlightBloc>().add(
                    SearchDepartureAirport(value),
                  );
                } else {
                  context.read<HomeFlightBloc>().add(
                    SearchArrivalAirport(value),
                  );
                }
              } else {
                _removeOverlay();
              }
            },
            onTap: () {
              if (_controller.text.isNotEmpty) {
                setState(() => _showResults = true);
              }
            },
          );
        },
      ),
    );
  }
}
