import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/home/view/home_flight_form.dart';
import 'package:bagtrip/home/view/home_hotel_form.dart';
import 'package:bagtrip/home/view/home_other_form.dart';
import 'package:bagtrip/home/widgets/home_top_cards.dart';
import 'package:flutter/material.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late PageController _headerController;
  late PageController _bodyController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Start at a high index divisible by 3 to simulate infinite backward scrolling
    const int initialPage = 3000;
    _headerController = PageController(
      viewportFraction: 0.85,
      initialPage: initialPage,
    );
    _bodyController = PageController(initialPage: initialPage);
  }

  @override
  void dispose() {
    _headerController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);

    if (_headerController.hasClients &&
        _headerController.page?.round() != index) {
      _headerController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }

    if (_bodyController.hasClients && _bodyController.page?.round() != index) {
      _bodyController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverToBoxAdapter(
            child: Column(
              children: [
                HomeTopCards(
                  controller: _headerController,
                  onPageChanged: _onPageChanged,
                ),
                const SizedBox(height: AppSize.boxSize16),
              ],
            ),
          ),
        ];
      },
      body: PageView.builder(
        controller: _bodyController,
        onPageChanged: _onPageChanged,
        itemBuilder: (context, index) {
          final formIndex = index % 3;
          switch (formIndex) {
            case 0:
              return const HomeFlightForm();
            case 1:
              return const HomeHotelForm();
            case 2:
              return const HomeOtherForm();
            default:
              return const SizedBox();
          }
        },
      ),
    );
  }
}
