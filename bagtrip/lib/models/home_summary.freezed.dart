// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'home_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HomeSummary {

@JsonKey(name: 'ongoingTrips') List<Trip> get ongoingTrips;@JsonKey(name: 'plannedTrips') List<Trip> get plannedTrips;@JsonKey(name: 'completedTrips') List<Trip> get completedTrips; User get user;@JsonKey(name: 'activeTripActivities') List<Activity> get activeTripActivities;@JsonKey(name: 'activeTripWeather') WeatherSummary? get activeTripWeather;
/// Create a copy of HomeSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HomeSummaryCopyWith<HomeSummary> get copyWith => _$HomeSummaryCopyWithImpl<HomeSummary>(this as HomeSummary, _$identity);

  /// Serializes this HomeSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomeSummary&&const DeepCollectionEquality().equals(other.ongoingTrips, ongoingTrips)&&const DeepCollectionEquality().equals(other.plannedTrips, plannedTrips)&&const DeepCollectionEquality().equals(other.completedTrips, completedTrips)&&(identical(other.user, user) || other.user == user)&&const DeepCollectionEquality().equals(other.activeTripActivities, activeTripActivities)&&(identical(other.activeTripWeather, activeTripWeather) || other.activeTripWeather == activeTripWeather));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(ongoingTrips),const DeepCollectionEquality().hash(plannedTrips),const DeepCollectionEquality().hash(completedTrips),user,const DeepCollectionEquality().hash(activeTripActivities),activeTripWeather);

@override
String toString() {
  return 'HomeSummary(ongoingTrips: $ongoingTrips, plannedTrips: $plannedTrips, completedTrips: $completedTrips, user: $user, activeTripActivities: $activeTripActivities, activeTripWeather: $activeTripWeather)';
}


}

/// @nodoc
abstract mixin class $HomeSummaryCopyWith<$Res>  {
  factory $HomeSummaryCopyWith(HomeSummary value, $Res Function(HomeSummary) _then) = _$HomeSummaryCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'ongoingTrips') List<Trip> ongoingTrips,@JsonKey(name: 'plannedTrips') List<Trip> plannedTrips,@JsonKey(name: 'completedTrips') List<Trip> completedTrips, User user,@JsonKey(name: 'activeTripActivities') List<Activity> activeTripActivities,@JsonKey(name: 'activeTripWeather') WeatherSummary? activeTripWeather
});


$UserCopyWith<$Res> get user;$WeatherSummaryCopyWith<$Res>? get activeTripWeather;

}
/// @nodoc
class _$HomeSummaryCopyWithImpl<$Res>
    implements $HomeSummaryCopyWith<$Res> {
  _$HomeSummaryCopyWithImpl(this._self, this._then);

  final HomeSummary _self;
  final $Res Function(HomeSummary) _then;

/// Create a copy of HomeSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ongoingTrips = null,Object? plannedTrips = null,Object? completedTrips = null,Object? user = null,Object? activeTripActivities = null,Object? activeTripWeather = freezed,}) {
  return _then(_self.copyWith(
ongoingTrips: null == ongoingTrips ? _self.ongoingTrips : ongoingTrips // ignore: cast_nullable_to_non_nullable
as List<Trip>,plannedTrips: null == plannedTrips ? _self.plannedTrips : plannedTrips // ignore: cast_nullable_to_non_nullable
as List<Trip>,completedTrips: null == completedTrips ? _self.completedTrips : completedTrips // ignore: cast_nullable_to_non_nullable
as List<Trip>,user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as User,activeTripActivities: null == activeTripActivities ? _self.activeTripActivities : activeTripActivities // ignore: cast_nullable_to_non_nullable
as List<Activity>,activeTripWeather: freezed == activeTripWeather ? _self.activeTripWeather : activeTripWeather // ignore: cast_nullable_to_non_nullable
as WeatherSummary?,
  ));
}
/// Create a copy of HomeSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserCopyWith<$Res> get user {
  
  return $UserCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}/// Create a copy of HomeSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WeatherSummaryCopyWith<$Res>? get activeTripWeather {
    if (_self.activeTripWeather == null) {
    return null;
  }

  return $WeatherSummaryCopyWith<$Res>(_self.activeTripWeather!, (value) {
    return _then(_self.copyWith(activeTripWeather: value));
  });
}
}


/// Adds pattern-matching-related methods to [HomeSummary].
extension HomeSummaryPatterns on HomeSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HomeSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HomeSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HomeSummary value)  $default,){
final _that = this;
switch (_that) {
case _HomeSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HomeSummary value)?  $default,){
final _that = this;
switch (_that) {
case _HomeSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'ongoingTrips')  List<Trip> ongoingTrips, @JsonKey(name: 'plannedTrips')  List<Trip> plannedTrips, @JsonKey(name: 'completedTrips')  List<Trip> completedTrips,  User user, @JsonKey(name: 'activeTripActivities')  List<Activity> activeTripActivities, @JsonKey(name: 'activeTripWeather')  WeatherSummary? activeTripWeather)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HomeSummary() when $default != null:
return $default(_that.ongoingTrips,_that.plannedTrips,_that.completedTrips,_that.user,_that.activeTripActivities,_that.activeTripWeather);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'ongoingTrips')  List<Trip> ongoingTrips, @JsonKey(name: 'plannedTrips')  List<Trip> plannedTrips, @JsonKey(name: 'completedTrips')  List<Trip> completedTrips,  User user, @JsonKey(name: 'activeTripActivities')  List<Activity> activeTripActivities, @JsonKey(name: 'activeTripWeather')  WeatherSummary? activeTripWeather)  $default,) {final _that = this;
switch (_that) {
case _HomeSummary():
return $default(_that.ongoingTrips,_that.plannedTrips,_that.completedTrips,_that.user,_that.activeTripActivities,_that.activeTripWeather);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'ongoingTrips')  List<Trip> ongoingTrips, @JsonKey(name: 'plannedTrips')  List<Trip> plannedTrips, @JsonKey(name: 'completedTrips')  List<Trip> completedTrips,  User user, @JsonKey(name: 'activeTripActivities')  List<Activity> activeTripActivities, @JsonKey(name: 'activeTripWeather')  WeatherSummary? activeTripWeather)?  $default,) {final _that = this;
switch (_that) {
case _HomeSummary() when $default != null:
return $default(_that.ongoingTrips,_that.plannedTrips,_that.completedTrips,_that.user,_that.activeTripActivities,_that.activeTripWeather);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HomeSummary implements HomeSummary {
  const _HomeSummary({@JsonKey(name: 'ongoingTrips') final  List<Trip> ongoingTrips = const [], @JsonKey(name: 'plannedTrips') final  List<Trip> plannedTrips = const [], @JsonKey(name: 'completedTrips') final  List<Trip> completedTrips = const [], required this.user, @JsonKey(name: 'activeTripActivities') final  List<Activity> activeTripActivities = const [], @JsonKey(name: 'activeTripWeather') this.activeTripWeather}): _ongoingTrips = ongoingTrips,_plannedTrips = plannedTrips,_completedTrips = completedTrips,_activeTripActivities = activeTripActivities;
  factory _HomeSummary.fromJson(Map<String, dynamic> json) => _$HomeSummaryFromJson(json);

 final  List<Trip> _ongoingTrips;
@override@JsonKey(name: 'ongoingTrips') List<Trip> get ongoingTrips {
  if (_ongoingTrips is EqualUnmodifiableListView) return _ongoingTrips;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_ongoingTrips);
}

 final  List<Trip> _plannedTrips;
@override@JsonKey(name: 'plannedTrips') List<Trip> get plannedTrips {
  if (_plannedTrips is EqualUnmodifiableListView) return _plannedTrips;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_plannedTrips);
}

 final  List<Trip> _completedTrips;
@override@JsonKey(name: 'completedTrips') List<Trip> get completedTrips {
  if (_completedTrips is EqualUnmodifiableListView) return _completedTrips;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_completedTrips);
}

@override final  User user;
 final  List<Activity> _activeTripActivities;
@override@JsonKey(name: 'activeTripActivities') List<Activity> get activeTripActivities {
  if (_activeTripActivities is EqualUnmodifiableListView) return _activeTripActivities;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_activeTripActivities);
}

@override@JsonKey(name: 'activeTripWeather') final  WeatherSummary? activeTripWeather;

/// Create a copy of HomeSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HomeSummaryCopyWith<_HomeSummary> get copyWith => __$HomeSummaryCopyWithImpl<_HomeSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HomeSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HomeSummary&&const DeepCollectionEquality().equals(other._ongoingTrips, _ongoingTrips)&&const DeepCollectionEquality().equals(other._plannedTrips, _plannedTrips)&&const DeepCollectionEquality().equals(other._completedTrips, _completedTrips)&&(identical(other.user, user) || other.user == user)&&const DeepCollectionEquality().equals(other._activeTripActivities, _activeTripActivities)&&(identical(other.activeTripWeather, activeTripWeather) || other.activeTripWeather == activeTripWeather));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_ongoingTrips),const DeepCollectionEquality().hash(_plannedTrips),const DeepCollectionEquality().hash(_completedTrips),user,const DeepCollectionEquality().hash(_activeTripActivities),activeTripWeather);

@override
String toString() {
  return 'HomeSummary(ongoingTrips: $ongoingTrips, plannedTrips: $plannedTrips, completedTrips: $completedTrips, user: $user, activeTripActivities: $activeTripActivities, activeTripWeather: $activeTripWeather)';
}


}

/// @nodoc
abstract mixin class _$HomeSummaryCopyWith<$Res> implements $HomeSummaryCopyWith<$Res> {
  factory _$HomeSummaryCopyWith(_HomeSummary value, $Res Function(_HomeSummary) _then) = __$HomeSummaryCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'ongoingTrips') List<Trip> ongoingTrips,@JsonKey(name: 'plannedTrips') List<Trip> plannedTrips,@JsonKey(name: 'completedTrips') List<Trip> completedTrips, User user,@JsonKey(name: 'activeTripActivities') List<Activity> activeTripActivities,@JsonKey(name: 'activeTripWeather') WeatherSummary? activeTripWeather
});


@override $UserCopyWith<$Res> get user;@override $WeatherSummaryCopyWith<$Res>? get activeTripWeather;

}
/// @nodoc
class __$HomeSummaryCopyWithImpl<$Res>
    implements _$HomeSummaryCopyWith<$Res> {
  __$HomeSummaryCopyWithImpl(this._self, this._then);

  final _HomeSummary _self;
  final $Res Function(_HomeSummary) _then;

/// Create a copy of HomeSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ongoingTrips = null,Object? plannedTrips = null,Object? completedTrips = null,Object? user = null,Object? activeTripActivities = null,Object? activeTripWeather = freezed,}) {
  return _then(_HomeSummary(
ongoingTrips: null == ongoingTrips ? _self._ongoingTrips : ongoingTrips // ignore: cast_nullable_to_non_nullable
as List<Trip>,plannedTrips: null == plannedTrips ? _self._plannedTrips : plannedTrips // ignore: cast_nullable_to_non_nullable
as List<Trip>,completedTrips: null == completedTrips ? _self._completedTrips : completedTrips // ignore: cast_nullable_to_non_nullable
as List<Trip>,user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as User,activeTripActivities: null == activeTripActivities ? _self._activeTripActivities : activeTripActivities // ignore: cast_nullable_to_non_nullable
as List<Activity>,activeTripWeather: freezed == activeTripWeather ? _self.activeTripWeather : activeTripWeather // ignore: cast_nullable_to_non_nullable
as WeatherSummary?,
  ));
}

/// Create a copy of HomeSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserCopyWith<$Res> get user {
  
  return $UserCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}/// Create a copy of HomeSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WeatherSummaryCopyWith<$Res>? get activeTripWeather {
    if (_self.activeTripWeather == null) {
    return null;
  }

  return $WeatherSummaryCopyWith<$Res>(_self.activeTripWeather!, (value) {
    return _then(_self.copyWith(activeTripWeather: value));
  });
}
}

// dart format on
