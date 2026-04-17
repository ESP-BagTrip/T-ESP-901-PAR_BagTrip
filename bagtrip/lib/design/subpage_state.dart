/// Screen state taxonomy for the routed subpages (`/activities`,
/// `/transports`, `/accommodations`, `/baggage`, `/budget`, `/shares`).
///
/// Rather than branching on `(loading, error, count, role, isCompleted)`
/// inline in every view, each subpage calls [resolveSubpageState] once and
/// then renders one of six distinct layouts. This keeps the layout decision
/// tree in a single, testable place and lets the primitives
/// (`StateResponsiveHero`, `BlankCanvasHero`, `DensityAwareListView`,
/// `ScrollReactiveFooter`) accept the state as a first-class input.
///
/// See `/Users/yanislounadi/.claude/plans/curried-launching-perlis.md`
/// "Modèle d'état à 6 strates" for the full spec.
enum SubpageScreenState {
  /// First render before any data has landed.
  booting,

  /// Data loaded, zero items, editable. The empty state *is* the hero.
  blankCanvas,

  /// 1–3 items, editable. Content breathes (24pt padding, large cards).
  sparse,

  /// 4+ items, editable. Content is dense (12pt padding, compact cards,
  /// optional filter chips above density thresholds).
  dense,

  /// Read-only because the viewer role isn't allowed to edit this trip.
  viewer,

  /// Trip marked completed — read-only + archive presentation (muted, date
  /// range in hero, single "Give a review" tertiary CTA).
  archive,

  /// Data fetch failed. Hero-style error card with retry.
  error,
}

/// Map a subpage's concrete state to a [SubpageScreenState].
///
/// The ordering of the branches matters:
/// - error wins over everything (we never show stale content on top of a
///   failure).
/// - loading wins over role decisions.
/// - role/isCompleted decide before we count items, because a viewer with
///   0 items should see "viewer + empty" (rendered as viewer — no blank
///   canvas CTA), not "blank canvas".
///
/// [denseThreshold] defaults to 4. Callers that want a different breakpoint
/// (e.g. baggage wants filter chips at 15+, but sparse/dense crossover stays
/// at 4) should override only that threshold.
SubpageScreenState resolveSubpageState({
  required bool isLoading,
  required bool hasError,
  required int count,
  required bool canEdit,
  required bool isCompleted,
  int denseThreshold = 4,
}) {
  if (hasError) return SubpageScreenState.error;
  if (isLoading) return SubpageScreenState.booting;
  if (isCompleted) return SubpageScreenState.archive;
  if (!canEdit) return SubpageScreenState.viewer;
  if (count == 0) return SubpageScreenState.blankCanvas;
  if (count < denseThreshold) return SubpageScreenState.sparse;
  return SubpageScreenState.dense;
}

/// Density band — a simpler projection used by primitives that only need to
/// pick padding/typography (hero, list, sticky footer) and don't care about
/// viewer/archive/error which are handled by outer composition.
enum HeroDensity { blankCanvas, sparse, dense }

/// Project a screen state onto a density band for layout decisions.
/// Returns null for states that don't participate in density (error,
/// booting) — caller renders those outside the density-aware pipeline.
HeroDensity? densityOf(SubpageScreenState state) {
  switch (state) {
    case SubpageScreenState.blankCanvas:
      return HeroDensity.blankCanvas;
    case SubpageScreenState.sparse:
      return HeroDensity.sparse;
    case SubpageScreenState.dense:
    case SubpageScreenState.viewer:
    case SubpageScreenState.archive:
      // Viewer and archive render at dense density (compact, content-first)
      // but without edit affordances — outer composition handles that.
      return HeroDensity.dense;
    case SubpageScreenState.booting:
    case SubpageScreenState.error:
      return null;
  }
}
