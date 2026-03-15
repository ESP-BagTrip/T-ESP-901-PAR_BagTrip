import 'package:bagtrip/booking/bloc/booking_bloc.dart';
import 'package:bagtrip/components/adaptive/adaptive_scaffold.dart';
import 'package:bagtrip/profile/bloc/user_profile_bloc.dart';
import 'package:bagtrip/profile/view/profile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final userProfileBloc = context.read<UserProfileBloc>();
    final bookingBloc = context.read<BookingBloc>();

    if (userProfileBloc.state is UserProfileInitial) {
      userProfileBloc.add(LoadUserProfile());
      bookingBloc.add(LoadBookings());
    } else if (userProfileBloc.state is UserProfileError) {
      userProfileBloc.add(ResetUserProfile());
      userProfileBloc.add(LoadUserProfile());
      bookingBloc.add(LoadBookings());
    }

    return const AdaptiveScaffold(
      body: SafeArea(left: false, right: false, child: ProfileView()),
    );
  }
}
