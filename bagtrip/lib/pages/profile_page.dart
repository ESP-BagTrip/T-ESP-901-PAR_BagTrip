import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/profile/bloc/user_profile_bloc.dart';
import 'package:bagtrip/profile/view/profile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final userProfileBloc = context.read<UserProfileBloc>();

    if (userProfileBloc.state is UserProfileInitial) {
      userProfileBloc.add(LoadUserProfile());
    } else if (userProfileBloc.state is UserProfileError) {
      userProfileBloc.add(ResetUserProfile());
      userProfileBloc.add(LoadUserProfile());
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: const Scaffold(
        backgroundColor: ColorName.primaryDark,
        body: ProfileView(),
      ),
    );
  }
}
