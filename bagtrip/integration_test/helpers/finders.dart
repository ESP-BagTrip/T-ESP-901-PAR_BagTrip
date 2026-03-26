import 'package:bagtrip/home/view/active_trip_home_view.dart';
import 'package:bagtrip/home/view/onboarding_home_view.dart';
import 'package:bagtrip/home/view/trip_manager_home_view.dart';
import 'package:bagtrip/plan_trip/view/plan_trip_flow_page.dart';
import 'package:bagtrip/trip_detail/view/trip_detail_page.dart';
import 'package:bagtrip/post_trip/view/post_trip_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ─── ValueKey-based finders (from home_view.dart) ───────────────────────────
final homeLoading = find.byKey(const ValueKey('home-loading'));
final homeNewUser = find.byKey(const ValueKey('home-new-user'));
final homeActiveTrip = find.byKey(const ValueKey('home-active-trip'));
final homeTripManager = find.byKey(const ValueKey('home-trip-manager'));
final homeError = find.byKey(const ValueKey('home-error'));

// ─── Type-based finders ─────────────────────────────────────────────────────
final onboardingHomeView = find.byType(OnboardingHomeView);
final activeTripHomeView = find.byType(ActiveTripHomeView);
final tripManagerHomeView = find.byType(TripManagerHomeView);
final planTripFlowPage = find.byType(PlanTripFlowPage);
final tripDetailPage = find.byType(TripDetailPage);
final postTripPage = find.byType(PostTripPage);
