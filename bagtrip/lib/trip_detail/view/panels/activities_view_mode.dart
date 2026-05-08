/// How the Activities tab presents its rows.
///
/// The mode is independent from the underlying data: every view reads
/// the same ``state.activities`` list and surfaces it differently —
/// the timeline groups by trip day, the list flattens chronologically,
/// the categories bucket by [ActivityCategory]. Adding a new mode is
/// a switch-case in the panel; the data layer never has to know.
enum ActivitiesViewMode {
  /// Day-by-day picker (J1, J2, …) + activities for the selected day.
  /// The default — closest to "what should I do tomorrow?".
  timeline,

  /// Flat chronological list (date asc), with the "Unscheduled"
  /// section appended at the bottom. Best for a long trip when the
  /// per-day chunking gets in the way.
  list,

  /// Grouped by [ActivityCategory]. Best while planning, to balance
  /// the trip across food / culture / nature / shopping.
  category,
}
