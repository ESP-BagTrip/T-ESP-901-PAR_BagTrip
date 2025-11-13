import 'package:flutter/material.dart';
import '../widgets/airport_search_field.dart';
import '../models/airport_type.dart';
import 'package:bagtrip/gen/colors.gen.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _tripTypeIndex = 0;
  int _adults = 1;
  int _children = 0;
  int _infants = 0;
  int _selectedClass = 0;
  late PageController _carouselController;
  int _currentCarouselPage = 0;

  Color get _accent => const Color(0xFF28B4B0);

  @override
  void initState() {
    super.initState();
    _carouselController = PageController(viewportFraction: 0.7);
    _carouselController.addListener(() {
      setState(() {
        _currentCarouselPage = _carouselController.page?.round() ?? 0;
      });
    });
  }

  @override
  void dispose() {
    _carouselController.dispose();
    super.dispose();
  }

  Widget _buildTopCards(BuildContext context) {
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
            controller: _carouselController,
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
                              style: Theme.of(
                                context,
                              ).textTheme.titleLarge?.copyWith(
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
        // Dots indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(cards.length, (index) {
            return Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    _currentCarouselPage == index ? _accent : ColorName.primary,
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildTripTypeSelector() {
    final labels = ['Aller simple', 'Aller-retour', 'Multidestination'];
    // Distribute space equally between the options and avoid scrolling
    return SizedBox(
      height: 42,
      child: Row(
        children: List.generate(labels.length, (i) {
          final selected = i == _tripTypeIndex;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i == labels.length - 1 ? 0 : 8.0),
              child: TextButton(
                style: TextButton.styleFrom(
                  // force consistent height and allow width to be governed by Expanded
                  minimumSize: const Size.fromHeight(42),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  backgroundColor:
                      selected ? _accent : ColorName.primarySoftLight,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => setState(() => _tripTypeIndex = i),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    labels[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? Colors.white : ColorName.primary,
                    ),
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
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: ColorName.primarySoftLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: _accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: ColorName.primarySoftLight,
                      borderRadius: BorderRadius.circular(16),
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

  Widget _buildClassSelector() {
    final labels = ['Économique', 'Premium', 'Business'];
    return Row(
      children: List.generate(labels.length, (i) {
        final selected = _selectedClass == i;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == labels.length - 1 ? 0 : 8.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                // enforce consistent touch target height and let Expanded control width
                minimumSize: const Size.fromHeight(42),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                backgroundColor:
                    selected ? _accent : ColorName.primarySoftLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              onPressed: () => setState(() => _selectedClass = i),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  labels[i],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? Colors.white : ColorName.primary,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildAirportField(
    AirportType type,
    void Function(Map<String, dynamic>?, AirportType) onSelected,
  ) {
    return AirportSearchField(
      type: type,
      hintText: type.hintText,
      onSelected: onSelected,
    );
  }

  // When TextField is selected, open date picker
  Widget _buildDateField(String hint) {
    return TextField(
      readOnly: true,
      decoration: InputDecoration(
        hintStyle: const TextStyle(fontSize: 13, color: ColorName.primary),
        border: InputBorder.none,
        hintText: hint,
      ),
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime(2101),
        );
        if (pickedDate != null) {
          // Handle the selected date
        }
      },
    );
  }

  Widget _buildPriceField() {
    return const TextField(
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        hintStyle: TextStyle(fontSize: 13, color: ColorName.primary),
        border: InputBorder.none,
        hintText: 'Prix maximum (€)',
      ),
    );
  }

  Widget _buildPassengersRow() {
    Widget counter(
      String label,
      int value,
      VoidCallback add,
      VoidCallback sub,
    ) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  color: ColorName.primary,
                  onPressed: sub,
                  padding: EdgeInsets.zero,
                  iconSize: 20,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: ColorName.primarySoftLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('$value'),
              ),
              SizedBox(
                width: 32,
                height: 32,
                child: IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  color: ColorName.primary,
                  onPressed: add,
                  padding: EdgeInsets.zero,
                  iconSize: 20,
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
            padding: const EdgeInsets.only(right: 8.0),
            child: counter(
              'Adultes',
              _adults,
              () => setState(() => _adults++),
              () => setState(() => _adults = (_adults > 1 ? _adults - 1 : 1)),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: counter(
              'Enfants',
              _children,
              () => setState(() => _children++),
              () => setState(
                () => _children = (_children > 0 ? _children - 1 : 0),
              ),
            ),
          ),
        ),
        Expanded(
          child: counter(
            'Bébés',
            _infants,
            () => setState(() => _infants++),
            () => setState(() => _infants = (_infants > 0 ? _infants - 1 : 0)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTopCards(context),
        const SizedBox(height: 12),
        _buildTripTypeSelector(),
        const SizedBox(height: 4),
        _buildFieldRow(
          Icons.flight_takeoff,
          _buildAirportField(AirportType.departure, (airport, selectedType) {}),
        ),
        _buildFieldRow(
          Icons.flight_land,
          _buildAirportField(AirportType.arrival, (airport, selectedType) {}),
        ),
        Row(
          children: [
            Expanded(
              child: _buildFieldRow(
                Icons.calendar_today,
                _buildDateField('Date de départ'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildFieldRow(
                Icons.calendar_today,
                const Text(
                  'jj/mm/aaaa',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            ),
          ],
        ),
        _buildFieldRow(Icons.euro_symbol, _buildPriceField()),
        const SizedBox(height: 12),
        const Text(
          'Classe de voyage',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        _buildClassSelector(),
        const SizedBox(height: 16),
        const Text(
          'Passagers',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        _buildPassengersRow(),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              // Trigger search
            },
            child: const Text(
              'Rechercher votre vol',
              style: TextStyle(color: ColorName.primaryLight, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}
