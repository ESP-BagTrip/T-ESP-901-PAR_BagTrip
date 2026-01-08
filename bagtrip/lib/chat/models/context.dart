class ChatContext {
  final int version;
  final ContextState state;
  final ContextUI ui;

  ChatContext({required this.version, required this.state, required this.ui});

  factory ChatContext.fromJson(Map<String, dynamic> json) {
    return ChatContext(
      version: json['version'] as int,
      state: ContextState.fromJson(json['state'] as Map<String, dynamic>),
      ui: ContextUI.fromJson(json['ui'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {'version': version, 'state': state.toJson(), 'ui': ui.toJson()};
  }
}

class ContextState {
  final String
  stage; // "collecting_requirements" | "searching" | "proposing" | "booking" | "done"
  final Map<String, dynamic>? requirements;
  final Map<String, dynamic>? selected;

  ContextState({required this.stage, this.requirements, this.selected});

  factory ContextState.fromJson(Map<String, dynamic> json) {
    return ContextState(
      stage: json['stage'] as String,
      requirements: json['requirements'] as Map<String, dynamic>?,
      selected: json['selected'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stage': stage,
      if (requirements != null) 'requirements': requirements,
      if (selected != null) 'selected': selected,
    };
  }
}

class ContextUI {
  final List<WidgetData> widgets;
  final List<String> quickReplies;

  ContextUI({required this.widgets, required this.quickReplies});

  factory ContextUI.fromJson(Map<String, dynamic> json) {
    return ContextUI(
      widgets:
          (json['widgets'] as List<dynamic>?)
              ?.map((w) => WidgetData.fromJson(w as Map<String, dynamic>))
              .toList() ??
          [],
      quickReplies:
          (json['quick_replies'] as List<dynamic>?)
              ?.map((r) => r as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'widgets': widgets.map((w) => w.toJson()).toList(),
      'quick_replies': quickReplies,
    };
  }
}

class WidgetData {
  final String
  type; // "FLIGHT_OFFER_CARD" | "HOTEL_OFFER_CARD" | "ITINERARY_SUMMARY" | "WARNING"
  final String? offerId;
  final String? title;
  final String? subtitle;
  final Map<String, dynamic>? data;
  final List<WidgetAction> actions;

  WidgetData({
    required this.type,
    this.offerId,
    this.title,
    this.subtitle,
    this.data,
    required this.actions,
  });

  factory WidgetData.fromJson(Map<String, dynamic> json) {
    return WidgetData(
      type: json['type'] as String,
      offerId: json['offer_id'] as String?,
      title: json['title'] as String?,
      subtitle: json['subtitle'] as String?,
      data: json['data'] as Map<String, dynamic>?,
      actions:
          (json['actions'] as List<dynamic>?)
              ?.map((a) => WidgetAction.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      if (offerId != null) 'offer_id': offerId,
      if (title != null) 'title': title,
      if (subtitle != null) 'subtitle': subtitle,
      if (data != null) 'data': data,
      'actions': actions.map((a) => a.toJson()).toList(),
    };
  }
}

class WidgetAction {
  final String
  type; // "SELECT_FLIGHT" | "BOOK_FLIGHT" | "SELECT_HOTEL" | "BOOK_HOTEL"
  final String label;

  WidgetAction({required this.type, required this.label});

  factory WidgetAction.fromJson(Map<String, dynamic> json) {
    return WidgetAction(
      type: json['type'] as String,
      label: json['label'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'type': type, 'label': label};
  }
}
