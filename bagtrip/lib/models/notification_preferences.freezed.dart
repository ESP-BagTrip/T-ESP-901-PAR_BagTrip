// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notification_preferences.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NotificationPreferences {

@JsonKey(name: 'push_enabled') bool get pushEnabled;@JsonKey(name: 'flight_reminders') bool get flightReminders;@JsonKey(name: 'activity_reminders') bool get activityReminders;@JsonKey(name: 'trip_updates') bool get tripUpdates;@JsonKey(name: 'budget_alerts') bool get budgetAlerts; bool get social;
/// Create a copy of NotificationPreferences
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotificationPreferencesCopyWith<NotificationPreferences> get copyWith => _$NotificationPreferencesCopyWithImpl<NotificationPreferences>(this as NotificationPreferences, _$identity);

  /// Serializes this NotificationPreferences to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotificationPreferences&&(identical(other.pushEnabled, pushEnabled) || other.pushEnabled == pushEnabled)&&(identical(other.flightReminders, flightReminders) || other.flightReminders == flightReminders)&&(identical(other.activityReminders, activityReminders) || other.activityReminders == activityReminders)&&(identical(other.tripUpdates, tripUpdates) || other.tripUpdates == tripUpdates)&&(identical(other.budgetAlerts, budgetAlerts) || other.budgetAlerts == budgetAlerts)&&(identical(other.social, social) || other.social == social));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,pushEnabled,flightReminders,activityReminders,tripUpdates,budgetAlerts,social);

@override
String toString() {
  return 'NotificationPreferences(pushEnabled: $pushEnabled, flightReminders: $flightReminders, activityReminders: $activityReminders, tripUpdates: $tripUpdates, budgetAlerts: $budgetAlerts, social: $social)';
}


}

/// @nodoc
abstract mixin class $NotificationPreferencesCopyWith<$Res>  {
  factory $NotificationPreferencesCopyWith(NotificationPreferences value, $Res Function(NotificationPreferences) _then) = _$NotificationPreferencesCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'push_enabled') bool pushEnabled,@JsonKey(name: 'flight_reminders') bool flightReminders,@JsonKey(name: 'activity_reminders') bool activityReminders,@JsonKey(name: 'trip_updates') bool tripUpdates,@JsonKey(name: 'budget_alerts') bool budgetAlerts, bool social
});




}
/// @nodoc
class _$NotificationPreferencesCopyWithImpl<$Res>
    implements $NotificationPreferencesCopyWith<$Res> {
  _$NotificationPreferencesCopyWithImpl(this._self, this._then);

  final NotificationPreferences _self;
  final $Res Function(NotificationPreferences) _then;

/// Create a copy of NotificationPreferences
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? pushEnabled = null,Object? flightReminders = null,Object? activityReminders = null,Object? tripUpdates = null,Object? budgetAlerts = null,Object? social = null,}) {
  return _then(_self.copyWith(
pushEnabled: null == pushEnabled ? _self.pushEnabled : pushEnabled // ignore: cast_nullable_to_non_nullable
as bool,flightReminders: null == flightReminders ? _self.flightReminders : flightReminders // ignore: cast_nullable_to_non_nullable
as bool,activityReminders: null == activityReminders ? _self.activityReminders : activityReminders // ignore: cast_nullable_to_non_nullable
as bool,tripUpdates: null == tripUpdates ? _self.tripUpdates : tripUpdates // ignore: cast_nullable_to_non_nullable
as bool,budgetAlerts: null == budgetAlerts ? _self.budgetAlerts : budgetAlerts // ignore: cast_nullable_to_non_nullable
as bool,social: null == social ? _self.social : social // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [NotificationPreferences].
extension NotificationPreferencesPatterns on NotificationPreferences {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NotificationPreferences value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NotificationPreferences() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NotificationPreferences value)  $default,){
final _that = this;
switch (_that) {
case _NotificationPreferences():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NotificationPreferences value)?  $default,){
final _that = this;
switch (_that) {
case _NotificationPreferences() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'push_enabled')  bool pushEnabled, @JsonKey(name: 'flight_reminders')  bool flightReminders, @JsonKey(name: 'activity_reminders')  bool activityReminders, @JsonKey(name: 'trip_updates')  bool tripUpdates, @JsonKey(name: 'budget_alerts')  bool budgetAlerts,  bool social)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NotificationPreferences() when $default != null:
return $default(_that.pushEnabled,_that.flightReminders,_that.activityReminders,_that.tripUpdates,_that.budgetAlerts,_that.social);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'push_enabled')  bool pushEnabled, @JsonKey(name: 'flight_reminders')  bool flightReminders, @JsonKey(name: 'activity_reminders')  bool activityReminders, @JsonKey(name: 'trip_updates')  bool tripUpdates, @JsonKey(name: 'budget_alerts')  bool budgetAlerts,  bool social)  $default,) {final _that = this;
switch (_that) {
case _NotificationPreferences():
return $default(_that.pushEnabled,_that.flightReminders,_that.activityReminders,_that.tripUpdates,_that.budgetAlerts,_that.social);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'push_enabled')  bool pushEnabled, @JsonKey(name: 'flight_reminders')  bool flightReminders, @JsonKey(name: 'activity_reminders')  bool activityReminders, @JsonKey(name: 'trip_updates')  bool tripUpdates, @JsonKey(name: 'budget_alerts')  bool budgetAlerts,  bool social)?  $default,) {final _that = this;
switch (_that) {
case _NotificationPreferences() when $default != null:
return $default(_that.pushEnabled,_that.flightReminders,_that.activityReminders,_that.tripUpdates,_that.budgetAlerts,_that.social);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NotificationPreferences implements NotificationPreferences {
  const _NotificationPreferences({@JsonKey(name: 'push_enabled') this.pushEnabled = true, @JsonKey(name: 'flight_reminders') this.flightReminders = true, @JsonKey(name: 'activity_reminders') this.activityReminders = true, @JsonKey(name: 'trip_updates') this.tripUpdates = true, @JsonKey(name: 'budget_alerts') this.budgetAlerts = true, this.social = true});
  factory _NotificationPreferences.fromJson(Map<String, dynamic> json) => _$NotificationPreferencesFromJson(json);

@override@JsonKey(name: 'push_enabled') final  bool pushEnabled;
@override@JsonKey(name: 'flight_reminders') final  bool flightReminders;
@override@JsonKey(name: 'activity_reminders') final  bool activityReminders;
@override@JsonKey(name: 'trip_updates') final  bool tripUpdates;
@override@JsonKey(name: 'budget_alerts') final  bool budgetAlerts;
@override@JsonKey() final  bool social;

/// Create a copy of NotificationPreferences
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NotificationPreferencesCopyWith<_NotificationPreferences> get copyWith => __$NotificationPreferencesCopyWithImpl<_NotificationPreferences>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NotificationPreferencesToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NotificationPreferences&&(identical(other.pushEnabled, pushEnabled) || other.pushEnabled == pushEnabled)&&(identical(other.flightReminders, flightReminders) || other.flightReminders == flightReminders)&&(identical(other.activityReminders, activityReminders) || other.activityReminders == activityReminders)&&(identical(other.tripUpdates, tripUpdates) || other.tripUpdates == tripUpdates)&&(identical(other.budgetAlerts, budgetAlerts) || other.budgetAlerts == budgetAlerts)&&(identical(other.social, social) || other.social == social));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,pushEnabled,flightReminders,activityReminders,tripUpdates,budgetAlerts,social);

@override
String toString() {
  return 'NotificationPreferences(pushEnabled: $pushEnabled, flightReminders: $flightReminders, activityReminders: $activityReminders, tripUpdates: $tripUpdates, budgetAlerts: $budgetAlerts, social: $social)';
}


}

/// @nodoc
abstract mixin class _$NotificationPreferencesCopyWith<$Res> implements $NotificationPreferencesCopyWith<$Res> {
  factory _$NotificationPreferencesCopyWith(_NotificationPreferences value, $Res Function(_NotificationPreferences) _then) = __$NotificationPreferencesCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'push_enabled') bool pushEnabled,@JsonKey(name: 'flight_reminders') bool flightReminders,@JsonKey(name: 'activity_reminders') bool activityReminders,@JsonKey(name: 'trip_updates') bool tripUpdates,@JsonKey(name: 'budget_alerts') bool budgetAlerts, bool social
});




}
/// @nodoc
class __$NotificationPreferencesCopyWithImpl<$Res>
    implements _$NotificationPreferencesCopyWith<$Res> {
  __$NotificationPreferencesCopyWithImpl(this._self, this._then);

  final _NotificationPreferences _self;
  final $Res Function(_NotificationPreferences) _then;

/// Create a copy of NotificationPreferences
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? pushEnabled = null,Object? flightReminders = null,Object? activityReminders = null,Object? tripUpdates = null,Object? budgetAlerts = null,Object? social = null,}) {
  return _then(_NotificationPreferences(
pushEnabled: null == pushEnabled ? _self.pushEnabled : pushEnabled // ignore: cast_nullable_to_non_nullable
as bool,flightReminders: null == flightReminders ? _self.flightReminders : flightReminders // ignore: cast_nullable_to_non_nullable
as bool,activityReminders: null == activityReminders ? _self.activityReminders : activityReminders // ignore: cast_nullable_to_non_nullable
as bool,tripUpdates: null == tripUpdates ? _self.tripUpdates : tripUpdates // ignore: cast_nullable_to_non_nullable
as bool,budgetAlerts: null == budgetAlerts ? _self.budgetAlerts : budgetAlerts // ignore: cast_nullable_to_non_nullable
as bool,social: null == social ? _self.social : social // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
