import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bagtrip/gen/colors.gen.dart';

import '../widgets/airport_search_field.dart';
import '../models/airport_type.dart';
import '../../design/tokens.dart';
import 'home_flight_bloc.dart';
import '../../design/widgets/primary_button.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeFlightBloc, HomeFlightState>(
      builder: (context, state) {
        if (state is HomeFlightError) {
          return Center(child: Text('Erreur: ${state.message}'));
        }

        final loadedState =
            state is HomeFlightLoaded ? state : HomeFlightLoaded();

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopCards(context, loadedState),
              const SizedBox(height: AppSize.boxSize16),
              _buildTripTypeSelector(context, loadedState),
              const SizedBox(height: AppSize.boxSize8),
              _buildFieldRow(
                Icons.flight_takeoff,
                _buildAirportField(
                  context,
                  AirportType.departure,
                  (Map<String, dynamic>? airport, AirportType selectedType) {
                    if (airport != null) {
                      context.read<HomeFlightBloc>().add(
                            SelectDepartureAirport(
                              airport.cast<String, dynamic>(),
                            ),
                          );
                    }
                  },
                ),
              ),
              _buildFieldRow(
                Icons.flight_land,
                _buildAirportField(
                  context,
                  AirportType.arrival,
                  (Map<String, dynamic>? airport, AirportType selectedType) {
                    if (airport != null) {
                      context.read<HomeFlightBloc>().add(
                            SelectArrivalAirport(
                              airport.cast<String, dynamic>(),
                            ),
                          );
                    }
                  },
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _buildFieldRow(
                      Icons.calendar_today,
                      _buildDateField(
                        context,
                        'jj/mm/aaaa',
                        (date) {
                          context
                              .read<HomeFlightBloc>()
                              .add(SetDepartureDate(date));
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSize.boxSize8),
                  Expanded(
                    child: _buildFieldRow(
                      Icons.calendar_today,
                      _buildDateField(
                        context,
                        'jj/mm/aaaa',
                        (date) {
                          context
                              .read<HomeFlightBloc>()
                              .add(SetReturnDate(date));
                        },
                      ),
                    ),
                  ),
                ],
              ),
              _buildFieldRow(
                Icons.euro_symbol,
                _buildPriceField(
                  context,
                  (price) {
                    context
                        .read<HomeFlightBloc>()
                        .add(SetMaxPrice(price));
                  },
                ),
              ),
              const SizedBox(height: AppSize.boxSize16),

              // Classe de voyage
              Text(
                'Classe de voyage',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSize.boxSize8),
              _buildClassSelector(context, loadedState),
              const SizedBox(height: AppSize.boxSize16),

              // Passagers
              Text(
                'Passagers',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSize.boxSize8),
              _buildPassengersRow(context, loadedState),
              const SizedBox(height: AppSize.boxSize16),

              // Search button using PrimaryButton
              PrimaryButton(
                label: 'Rechercher votre vol',
                isLoading: loadedState.isLoading,
                onPressed: () {
                  context.read<HomeFlightBloc>().add(SearchFlights());
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

Widget _buildTopCards(BuildContext context, HomeFlightLoaded state) {
  final cards = [
    {'title': 'VOL', 'icon': Icons.flight_takeoff},
    {'title': 'HÔTEL', 'icon': Icons.hotel},
    {'title': 'AUTRES', 'icon': Icons.explore},
  ];

  return Column(
    children: [
      SizedBox(
        height: 150,
        child: PageView.builder(
          itemCount: cards.length,
          itemBuilder: (context, index) {
            final card = cards[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(color: ColorName.secondary),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            card['icon'] as IconData,
                            color: ColorName.primaryLight,
                            size: 40,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            card['title'] as String,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: ColorName.primaryLight,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 12),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(cards.length, (index) {
          return Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: index == 0
                  ? ColorName.secondary
                  : ColorName.primarySoftLight,
            ),
          );
        }),
      ),
    ],
  );
}

Widget _buildTripTypeSelector(
  BuildContext context,
  HomeFlightLoaded state,
) {
  final labels = ['Aller simple', 'Aller-retour', 'Multidestination'];

  return SizedBox(
    height: AppSize.height42,
    child: Row(
      children: List.generate(labels.length, (i) {
        final selected = i == state.tripTypeIndex;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: i == labels.length - 1 ? 0 : AppSpacing.space8,
            ),
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: selected
                    ? ColorName.secondary
                    : ColorName.primarySoftLight,
                foregroundColor:
                    selected ? Colors.white : ColorName.primary,
              ),
              onPressed: () {
                context.read<HomeFlightBloc>().add(SetTripType(i));
              },
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  labels[i],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        );
      }),
    ),
  );
}

Widget _buildFieldRow(IconData icon, Widget field) {
  return Stack(
    children: [
      Padding(
        padding: AppSpacing.onlyTopSpace8,
        child: Row(
          children: [
            Container(
              width: AppSize.width42,
              height: AppSize.height42,
              decoration: const BoxDecoration(
                color: ColorName.primarySoftLight,
                borderRadius: AppRadius.large16,
              ),
              child: Icon(icon, color: ColorName.secondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: AppSize.height42,
                child: Container(
                  padding: AppSpacing.horizontalSpace16,
                  decoration: const BoxDecoration(
                    color: ColorName.primarySoftLight,
                    borderRadius: AppRadius.large16,
                  ),
                  child: field,
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

Widget _buildClassSelector(
  BuildContext context,
  HomeFlightLoaded state,
) {
  final labels = ['Économique', 'Premium', 'Business'];

  return Row(
    children: List.generate(labels.length, (i) {
      final selected = state.selectedClass == i;

      return Expanded(
        child: Padding(
          padding: EdgeInsets.only(
            right: i == labels.length - 1 ? 0 : AppSpacing.space8,
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: selected
                  ? ColorName.secondary
                  : ColorName.primarySoftLight,
              foregroundColor:
                  selected ? Colors.white : ColorName.primary,
              elevation: 0,
            ),
            onPressed: () {
              context.read<HomeFlightBloc>().add(SetTravelClass(i));
            },
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                labels[i],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      );
    }),
  );
}

Widget _buildAirportField(
  BuildContext context,
  AirportType type,
  void Function(Map<String, dynamic>?, AirportType) onSelected,
) {
  return AirportSearchField(
    type: type,
    hintText: type.hintText,
    onSelected: onSelected,
  );
}

Widget _buildDateField(
  BuildContext context,
  String hint,
  Function(DateTime) onDateSelected,
) {
  return TextField(
    readOnly: true,
    decoration: InputDecoration(
      hintText: hint,
    ),
    onTap: () async {
      final pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime(2101),
      );
      if (pickedDate != null) {
        onDateSelected(pickedDate);
      }
    },
  );
}

Widget _buildPriceField(
  BuildContext context,
  Function(double) onPriceChanged,
) {
  return TextField(
    keyboardType: TextInputType.number,
    decoration: const InputDecoration(
      hintText: 'Prix maximum (€)',
    ),
    onChanged: (value) {
      final price = double.tryParse(value) ?? 0.0;
      onPriceChanged(price);
    },
  );
}

Widget _buildPassengersRow(
  BuildContext context,
  HomeFlightLoaded state,
) {
  Widget counter(
    String label,
    int value,
    VoidCallback add,
    VoidCallback sub,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                color: ColorName.secondary,
                onPressed: sub,
                padding: EdgeInsets.zero,
                iconSize: 24,
              ),
            ),
            Container(
              padding: AppSpacing.allEdgeInsetSpace16,
              decoration: const BoxDecoration(
                color: ColorName.primarySoftLight,
                borderRadius: AppRadius.large16,
              ),
              child: Text('$value'),
            ),
            SizedBox(
              width: 32,
              height: 32,
              child: IconButton(
                icon: const Icon(Icons.add_circle_outline),
                color: ColorName.secondary,
                onPressed: add,
                padding: EdgeInsets.zero,
                iconSize: 24,
              ),
            ),
          ],
        ),
      ],
    );
  }

  return Row(
    children: [
      Expanded(
        child: Padding(
          padding: AppSpacing.onlyRightSpace8,
          child: counter(
            'Adultes',
            state.adults,
            () => context
                .read<HomeFlightBloc>()
                .add(SetAdults(state.adults + 1)),
            () => context.read<HomeFlightBloc>().add(
                  SetAdults(state.adults > 1 ? state.adults - 1 : 1),
                ),
          ),
        ),
      ),
      Expanded(
        child: Padding(
          padding: AppSpacing.onlyRightSpace8,
          child: counter(
            'Enfants',
            state.children,
            () => context
                .read<HomeFlightBloc>()
                .add(SetChildren(state.children + 1)),
            () => context.read<HomeFlightBloc>().add(
                  SetChildren(
                    state.children > 0 ? state.children - 1 : 0,
                  ),
                ),
          ),
        ),
      ),
      Expanded(
        child: counter(
          'Bébés',
          state.infants,
          () => context
              .read<HomeFlightBloc>()
              .add(SetInfants(state.infants + 1)),
          () => context.read<HomeFlightBloc>().add(
                SetInfants(
                  state.infants > 0 ? state.infants - 1 : 0,
                ),
              ),
        ),
      ),
    ],
  );
}
