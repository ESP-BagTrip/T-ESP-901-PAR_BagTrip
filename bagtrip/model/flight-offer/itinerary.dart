import 'segment.dart';

class Itinerary {
  final String duration;
  final List<Segment> segments;

  Itinerary({required this.duration, required this.segments});

  factory Itinerary.fromJson(Map<String, dynamic> json) => Itinerary(
    duration: json["duration"],
    segments: List<Segment>.from(
      json["segments"].map((x) => Segment.fromJson(x)),
    ),
  );

  Map<String, dynamic> toJson() => {
    "duration": duration,
    "segments": List<dynamic>.from(segments.map((x) => x.toJson())),
  };
}
