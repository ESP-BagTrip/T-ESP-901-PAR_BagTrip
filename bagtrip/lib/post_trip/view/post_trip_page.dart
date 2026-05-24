import 'package:bagtrip/post_trip/bloc/post_trip_bloc.dart';
import 'package:bagtrip/post_trip/view/post_trip_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PostTripPage extends StatelessWidget {
  final String tripId;

  const PostTripPage({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PostTripBloc()..add(LoadPostTripStats(tripId: tripId)),
      child: PostTripView(tripId: tripId),
    );
  }
}
