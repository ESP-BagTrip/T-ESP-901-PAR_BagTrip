import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/trip_creation/bloc/trip_creation_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DestinationSearchField extends StatefulWidget {
  final String? hintText;

  const DestinationSearchField({super.key, this.hintText});

  @override
  State<DestinationSearchField> createState() => _DestinationSearchFieldState();
}

class _DestinationSearchFieldState extends State<DestinationSearchField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<TripCreationBloc>().state;
    _controller = TextEditingController(text: state.destinationName ?? '');
    _focusNode = FocusNode();
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

  void _showOverlay(List<Map<String, dynamic>> locations) {
    _removeOverlay();
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final bloc = context.read<TripCreationBloc>();

    _overlayEntry = OverlayEntry(
      builder: (_) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          offset: Offset(0, size.height + 4),
          showWhenUnlinked: false,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            color: ColorName.surface,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: locations.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, index) {
                  final loc = locations[index];
                  final name = loc['name'] ?? loc['city'] ?? '';
                  final iata = loc['iataCode'] ?? '';
                  final country =
                      loc['countryName'] ?? loc['countryCode'] ?? '';
                  return ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.location_on_outlined,
                      size: 20,
                      color: ColorName.secondary,
                    ),
                    title: Text(
                      name.toString(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: FontFamily.b612,
                        color: ColorName.primaryTrueDark,
                      ),
                    ),
                    subtitle: Text(
                      [
                        iata,
                        country,
                      ].where((e) => e.toString().isNotEmpty).join(' \u2022 '),
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: FontFamily.b612,
                        color: ColorName.hint,
                      ),
                    ),
                    onTap: () {
                      _controller.text = name.toString();
                      _removeOverlay();
                      FocusManager.instance.primaryFocus?.unfocus();
                      setState(() => _showResults = false);
                      bloc.add(
                        SelectDestination(
                          name: name.toString(),
                          iata: iata.toString(),
                          country: country.toString(),
                        ),
                      );
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
      child: BlocListener<TripCreationBloc, TripCreationState>(
        listenWhen: (prev, curr) =>
            prev.locationResults != curr.locationResults,
        listener: (context, state) {
          if (state.locationResults != null &&
              state.locationResults!.isNotEmpty &&
              _showResults) {
            _showOverlay(state.locationResults!);
          } else {
            _removeOverlay();
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: ColorName.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ColorName.primarySoftLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                offset: const Offset(0, 2),
                blurRadius: 8,
              ),
            ],
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            style: const TextStyle(
              fontFamily: FontFamily.b612,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: ColorName.primaryTrueDark,
            ),
            decoration: InputDecoration(
              hintText: widget.hintText ?? 'Paris, Tokyo, New York...',
              hintStyle: const TextStyle(
                fontFamily: FontFamily.b612,
                color: ColorName.hint,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: ColorName.hint,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            onChanged: (value) {
              setState(() => _showResults = value.isNotEmpty);
              context.read<TripCreationBloc>().add(SearchDestination(value));
            },
          ),
        ),
      ),
    );
  }
}
