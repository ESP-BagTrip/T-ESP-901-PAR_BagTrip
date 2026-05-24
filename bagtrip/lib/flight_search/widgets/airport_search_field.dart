import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/flight_search/bloc/flight_search_bloc.dart';
import 'package:bagtrip/flight_search/models/airport_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
  // Cached results rendered by the live overlay. Updating this and calling
  // `markNeedsBuild` keeps the overlay alive across bloc emissions so a tap
  // on the current list isn't lost to a destroy/recreate race — which used
  // to happen when results shrank from N to 1 (SMP-190).
  List<Map<String, dynamic>> _overlayAirports = const [];

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
    _overlayAirports = airports;
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
      return;
    }

    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
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
                itemCount: _overlayAirports.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final airport = _overlayAirports[index];
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
                          .where((e) => e != null && e.toString().isNotEmpty)
                          .join(' \u2022 '),
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: FontFamily.b612,
                        color: AppColors.hint,
                      ),
                    ),
                    onTap: () {
                      _controller.text = airport['name'] ?? '';
                      _removeOverlay();
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
                  color: AppColors.hint,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return CompositedTransformTarget(
      link: _layerLink,
      child: BlocConsumer<FlightSearchBloc, FlightSearchState>(
        listener: (context, state) {
          if (state is FlightSearchLoaded &&
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
                color: widget.hasError ? ColorName.error : AppColors.hint,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (value) {
              setState(() => _showResults = value.isNotEmpty);
              if (value.length >= 2) {
                context.read<FlightSearchBloc>().add(
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
