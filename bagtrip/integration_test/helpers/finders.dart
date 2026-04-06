import 'package:bagtrip/home/view/active_trip_home_view.dart';
import 'package:bagtrip/home/view/idle_home_view.dart';
import 'package:bagtrip/plan_trip/view/plan_trip_flow_page.dart';
import 'package:bagtrip/trip_detail/view/trip_detail_page.dart';
import 'package:bagtrip/post_trip/view/post_trip_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ─── ValueKey-based finders (from home_view.dart) ───────────────────────────
final homeLoading = find.byKey(const ValueKey('home-loading'));
final homeIdle = find.byKey(const ValueKey('home-idle'));
final homeActiveTrip = find.byKey(const ValueKey('home-active-trip'));
final homeError = find.byKey(const ValueKey('home-error'));

// ─── Legacy aliases (kept for backward compatibility in tests) ──────────────
final homeNewUser = homeIdle;
final homeTripManager = homeIdle;

// ─── Type-based finders ─────────────────────────────────────────────────────
final idleHomeView = find.byType(IdleHomeView);
final activeTripHomeView = find.byType(ActiveTripHomeView);
final planTripFlowPage = find.byType(PlanTripFlowPage);
final tripDetailPage = find.byType(TripDetailPage);
final postTripPage = find.byType(PostTripPage);

// ─── Legacy aliases ─────────────────────────────────────────────────────────
final onboardingHomeView = idleHomeView;
final tripManagerHomeView = idleHomeView;
