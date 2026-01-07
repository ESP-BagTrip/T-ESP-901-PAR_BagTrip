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
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialValue?['name'] ?? '',
    );
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant AirportSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue &&
        widget.initialValue != null) {
      _controller.text = widget.initialValue?['name'] ?? '';
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    _controller.dispose();
    _focusNode.dispose();
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
              offset: Offset(0, size.height + 4),
              showWhenUnlinked: false,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: airports.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
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
                            color: ColorName.primary,
                          ),
                        ),
                        subtitle: Text(
                          [airport['iataCode'], airport['city']]
                              .where(
                                (e) => e != null && e.toString().isNotEmpty,
                              )
                              .join(' \u2022 '),
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: FontFamily.b612,
                            color: Color(0xFF9AA6AC),
                          ),
                        ),
                        onTap: () {
                          _controller.text = airport['name'] ?? '';
                          _removeOverlay();

                          // 🔥 POINT CLÉ : on reprend le contrôle du focus
                          FocusManager.instance.primaryFocus?.unfocus();

                          setState(() => _showResults = false);
                          widget.onSelected?.call(airport, widget.type);
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
    // Mode affichage (champ validé)
    if (widget.initialValue != null && !_showResults) {
      final airport = widget.initialValue!;
      return CompositedTransformTarget(
        link: _layerLink,
        child: GestureDetector(
          onTap: () {
            setState(() {
              _controller.clear();
              _showResults = true;
            });

            WidgetsBinding.instance.addPostFrameCallback((_) {
              _focusNode.requestFocus();
            });
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                airport['name'] ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    widget.style ??
                    const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: FontFamily.b612,
                      color: ColorName.primary,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                '${airport['iataCode']} · ${airport['countryName']}',
                style: const TextStyle(
                  fontSize: 13,
                  fontFamily: FontFamily.b612,
                  color: Color(0xFF9AA6AC),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Mode saisie
    return CompositedTransformTarget(
      link: _layerLink,
      child: BlocConsumer<HomeFlightBloc, HomeFlightState>(
        listener: (context, state) {
          if (state is HomeFlightLoaded &&
              state.searchResults != null &&
              _showResults) {
            _showOverlay(context, state.searchResults!);
          } else {
            _removeOverlay();
          }
        },
        builder: (context, state) {
          return TextField(
            controller: _controller,
            focusNode: _focusNode,
            textAlignVertical: TextAlignVertical.center,
            style:
                widget.style ??
                const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: FontFamily.b612,
                  color: ColorName.primary,
                ),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: FontFamily.b612,
                color:
                    widget.hasError ? ColorName.error : const Color(0xFF9AA6AC),
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (value) {
              setState(() => _showResults = value.isNotEmpty);
              if (value.length >= 2) {
                context.read<HomeFlightBloc>().add(
                  widget.type == AirportType.departure
                      ? SearchDepartureAirport(value)
                      : SearchArrivalAirport(value),
                );
              } else {
                _removeOverlay();
              }
            },
          );
        },
      ),
    );
  }
}
