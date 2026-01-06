import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/home/view/home_flight_form.dart';
import 'package:bagtrip/home/view/home_hotel_form.dart';
import 'package:bagtrip/home/view/home_other_form.dart';
import 'package:bagtrip/home/widgets/home_top_cards.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late PageController _headerController;
  late PageController _bodyController;

  bool _isHeaderActive = true;

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

    _headerController.addListener(_syncBodyToHeader);
    _bodyController.addListener(_syncHeaderToBody);
  }

  @override
  void dispose() {
    _headerController.removeListener(_syncBodyToHeader);
    _bodyController.removeListener(_syncHeaderToBody);
    _headerController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _syncBodyToHeader() {
    if (_isHeaderActive &&
        _headerController.hasClients &&
        _bodyController.hasClients) {
      _bodyController.jumpTo(_headerController.offset / 0.85);
    }
  }

  void _syncHeaderToBody() {
    if (!_isHeaderActive &&
        _headerController.hasClients &&
        _bodyController.hasClients) {
      _headerController.jumpTo(_bodyController.offset * 0.85);
    }
  }

  void _onPageChanged(int index) {
    // No need to rebuild the UI on page change as the index is not used in build
  }

  bool _onNotification(ScrollNotification notification, bool isHeader) {
    if (notification.metrics.axis != Axis.horizontal) return false;

    if (notification is UserScrollNotification) {
      if (notification.direction != ScrollDirection.idle) {
        _isHeaderActive = isHeader;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: NotificationListener<ScrollNotification>(
                onNotification: (n) => _onNotification(n, true),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    HomeTopCards(
                      controller: _headerController,
                      onPageChanged: _onPageChanged,
                    ),
                    const SizedBox(height: AppSize.boxSize16),
                  ],
                ),
              ),
            ),
          ];
        },
        body: NotificationListener<ScrollNotification>(
          onNotification: (n) => _onNotification(n, false),
          child: PageView.builder(
            allowImplicitScrolling: true,
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
        ),
      ),
    );
  }
}
