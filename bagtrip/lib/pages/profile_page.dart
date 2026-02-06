import 'package:bagtrip/profile/bloc/profile_bloc.dart';
import 'package:bagtrip/profile/view/profile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final profileBloc = context.read<ProfileBloc>();

    if (profileBloc.state is ProfileInitial) {
      profileBloc.add(LoadProfile());
    } else if (profileBloc.state is ProfileUnauthenticated) {
      profileBloc.add(ResetProfile());
      profileBloc.add(LoadProfile());
    }

    return BlocListener<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is ProfileUnauthenticated && context.mounted) {
          context.go('/login');
        }
      },
      child: Scaffold(
        body: BlocProvider.value(
          value: profileBloc,
          child: const SafeArea(
            left: false,
            right: false,
            child: ProfileView(),
          ),
        ),
      ),
    );
  }
}
