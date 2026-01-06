import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/home/bloc/home_flight_bloc.dart';
import 'package:bagtrip/home/models/airport_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../gen/colors.gen.dart';

class AirportSearchField extends StatefulWidget {
  final AirportType type;
  final String? hintText;
  final Map<String, dynamic>? initialValue;
  final void Function(Map<String, dynamic>?, AirportType)? onSelected;
  final bool hasError;
  final TextStyle? style;

  const AirportSearchField({
    super.key,
    required this.type,
    this.hintText,
    this.initialValue,
    this.onSelected,
    this.hasError = false,
    this.style,
  });

  @override
  State<AirportSearchField> createState() => _AirportSearchFieldState();
}

class _AirportSearchFieldState extends State<AirportSearchField> {
  late TextEditingController _controller;
  final LayerLink _layerLink = LayerLink();
  bool _showResults = false;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialValue?['name'] ?? '',
    );
  }

  @override
  void didUpdateWidget(AirportSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue) {
      if (widget.initialValue != null) {
        _controller.text = widget.initialValue?['name'] ?? '';
      }
    }
  }

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
                color: Colors.white,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.separated(
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
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: FontFamily.b612,
                          ),
                        ),
                        subtitle: Text(
                          '${airport['city'] ?? ''}, ${airport['countryCode'] ?? ''}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: FontFamily.b612,
                          ),
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
    // If we have a value selected, display the custom rich text instead of the text field
    if (widget.initialValue != null && !_showResults) {
      final city = widget.initialValue?['city'] ?? '';
      final name = widget.initialValue?['name'] ?? '';
      final code = widget.initialValue?['iataCode'] ?? '';
      final country =
          widget.initialValue?['countryName'] ?? ''; // or countryCode

      return CompositedTransformTarget(
        link: _layerLink,
        child: GestureDetector(
          onTap: () {
            // Switch to edit mode? Or just open search?
            // For now, let's just allow clearing by tapping X or similar,
            // or if the user taps the text, we could show the text field.
            // Simplified: show text field on tap.
            setState(() {
              _controller.text = ''; // Clear to start search
              _showResults = true; // Trigger search mode effectively
            });
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name.isNotEmpty
                    ? name
                    : city, // Prefer Name as primary per image "Paris Charles de Gaulle"
                style:
                    widget.style ??
                    const TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: ColorName.primary,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '$code \u00B7 $country', // CDG * France
                style: const TextStyle(
                  fontFamily: FontFamily.b612,
                  fontSize: 13,
                  color: Color(0xFF9AA6AC), // Greyish color
                ),
              ),
            ],
          ),
        ),
      );
    }

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
            textAlignVertical: TextAlignVertical.center,
            controller: _controller,
            style:
                widget.style ??
                const TextStyle(
                  fontFamily: FontFamily.b612,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: ColorName.primary,
                ),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: TextStyle(
                fontSize: 16,
                fontFamily: FontFamily.b612,
                color:
                    widget.hasError ? ColorName.error : const Color(0xFF9AA6AC),
                fontWeight: FontWeight.w500,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
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
