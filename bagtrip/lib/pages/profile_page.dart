import 'package:bagtrip/profile/bloc/profile_bloc.dart';
import 'package:bagtrip/profile/view/profile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the ProfileBloc from the parent context (provided in MyApp)
    final profileBloc = context.read<ProfileBloc>();

    // Load profile if not already loaded
    if (profileBloc.state is! ProfileLoaded) {
      profileBloc.add(LoadProfile());
    }

    return Scaffold(
      body: BlocProvider.value(
        value: profileBloc,
        child: const SafeArea(left: false, right: false, child: ProfileView()),
      ),
    );
  }
}
