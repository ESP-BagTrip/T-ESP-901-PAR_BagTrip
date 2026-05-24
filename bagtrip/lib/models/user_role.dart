/// The current user's role on a trip.
///
/// The wire format is the backend string (`OWNER` / `VIEWER` / `EDITOR`),
/// surfaced as `Trip.role`. The API omits the field for trips the user owns,
/// so a *null* role means [owner]. An *unrecognised* non-null value resolves
/// to the least-privileged [viewer] — failing safe so a new server-side role
/// can never accidentally grant edit access on an old client.
enum UserRole {
  owner('OWNER'),
  editor('EDITOR'),
  viewer('VIEWER');

  const UserRole(this.apiValue);

  final String apiValue;

  static UserRole fromApi(String? value) {
    if (value == null) return UserRole.owner;
    for (final r in UserRole.values) {
      if (r.apiValue == value) return r;
    }
    // Unknown role -> least privilege (fail-safe for permission checks).
    return UserRole.viewer;
  }
}
