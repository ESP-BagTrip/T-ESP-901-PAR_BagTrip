// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trip_home.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TripHomeStats {

 int get baggageCount; double get totalExpenses; int get nbTravelers; int? get daysUntilTrip; int? get tripDuration;
/// Create a copy of TripHomeStats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TripHomeStatsCopyWith<TripHomeStats> get copyWith => _$TripHomeStatsCopyWithImpl<TripHomeStats>(this as TripHomeStats, _$identity);

  /// Serializes this TripHomeStats to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TripHomeStats&&(identical(other.baggageCount, baggageCount) || other.baggageCount == baggageCount)&&(identical(other.totalExpenses, totalExpenses) || other.totalExpenses == totalExpenses)&&(identical(other.nbTravelers, nbTravelers) || other.nbTravelers == nbTravelers)&&(identical(other.daysUntilTrip, daysUntilTrip) || other.daysUntilTrip == daysUntilTrip)&&(identical(other.tripDuration, tripDuration) || other.tripDuration == tripDuration));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,baggageCount,totalExpenses,nbTravelers,daysUntilTrip,tripDuration);

@override
String toString() {
  return 'TripHomeStats(baggageCount: $baggageCount, totalExpenses: $totalExpenses, nbTravelers: $nbTravelers, daysUntilTrip: $daysUntilTrip, tripDuration: $tripDuration)';
}


}

/// @nodoc
abstract mixin class $TripHomeStatsCopyWith<$Res>  {
  factory $TripHomeStatsCopyWith(TripHomeStats value, $Res Function(TripHomeStats) _then) = _$TripHomeStatsCopyWithImpl;
@useResult
$Res call({
 int baggageCount, double totalExpenses, int nbTravelers, int? daysUntilTrip, int? tripDuration
});




}
/// @nodoc
class _$TripHomeStatsCopyWithImpl<$Res>
    implements $TripHomeStatsCopyWith<$Res> {
  _$TripHomeStatsCopyWithImpl(this._self, this._then);

  final TripHomeStats _self;
  final $Res Function(TripHomeStats) _then;

/// Create a copy of TripHomeStats
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? baggageCount = null,Object? totalExpenses = null,Object? nbTravelers = null,Object? daysUntilTrip = freezed,Object? tripDuration = freezed,}) {
  return _then(_self.copyWith(
baggageCount: null == baggageCount ? _self.baggageCount : baggageCount // ignore: cast_nullable_to_non_nullable
as int,totalExpenses: null == totalExpenses ? _self.totalExpenses : totalExpenses // ignore: cast_nullable_to_non_nullable
as double,nbTravelers: null == nbTravelers ? _self.nbTravelers : nbTravelers // ignore: cast_nullable_to_non_nullable
as int,daysUntilTrip: freezed == daysUntilTrip ? _self.daysUntilTrip : daysUntilTrip // ignore: cast_nullable_to_non_nullable
as int?,tripDuration: freezed == tripDuration ? _self.tripDuration : tripDuration // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [TripHomeStats].
extension TripHomeStatsPatterns on TripHomeStats {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TripHomeStats value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TripHomeStats() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TripHomeStats value)  $default,){
final _that = this;
switch (_that) {
case _TripHomeStats():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TripHomeStats value)?  $default,){
final _that = this;
switch (_that) {
case _TripHomeStats() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int baggageCount,  double totalExpenses,  int nbTravelers,  int? daysUntilTrip,  int? tripDuration)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TripHomeStats() when $default != null:
return $default(_that.baggageCount,_that.totalExpenses,_that.nbTravelers,_that.daysUntilTrip,_that.tripDuration);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int baggageCount,  double totalExpenses,  int nbTravelers,  int? daysUntilTrip,  int? tripDuration)  $default,) {final _that = this;
switch (_that) {
case _TripHomeStats():
return $default(_that.baggageCount,_that.totalExpenses,_that.nbTravelers,_that.daysUntilTrip,_that.tripDuration);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int baggageCount,  double totalExpenses,  int nbTravelers,  int? daysUntilTrip,  int? tripDuration)?  $default,) {final _that = this;
switch (_that) {
case _TripHomeStats() when $default != null:
return $default(_that.baggageCount,_that.totalExpenses,_that.nbTravelers,_that.daysUntilTrip,_that.tripDuration);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TripHomeStats implements TripHomeStats {
  const _TripHomeStats({this.baggageCount = 0, this.totalExpenses = 0.0, this.nbTravelers = 1, this.daysUntilTrip, this.tripDuration});
  factory _TripHomeStats.fromJson(Map<String, dynamic> json) => _$TripHomeStatsFromJson(json);

@override@JsonKey() final  int baggageCount;
@override@JsonKey() final  double totalExpenses;
@override@JsonKey() final  int nbTravelers;
@override final  int? daysUntilTrip;
@override final  int? tripDuration;

/// Create a copy of TripHomeStats
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TripHomeStatsCopyWith<_TripHomeStats> get copyWith => __$TripHomeStatsCopyWithImpl<_TripHomeStats>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TripHomeStatsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TripHomeStats&&(identical(other.baggageCount, baggageCount) || other.baggageCount == baggageCount)&&(identical(other.totalExpenses, totalExpenses) || other.totalExpenses == totalExpenses)&&(identical(other.nbTravelers, nbTravelers) || other.nbTravelers == nbTravelers)&&(identical(other.daysUntilTrip, daysUntilTrip) || other.daysUntilTrip == daysUntilTrip)&&(identical(other.tripDuration, tripDuration) || other.tripDuration == tripDuration));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,baggageCount,totalExpenses,nbTravelers,daysUntilTrip,tripDuration);

@override
String toString() {
  return 'TripHomeStats(baggageCount: $baggageCount, totalExpenses: $totalExpenses, nbTravelers: $nbTravelers, daysUntilTrip: $daysUntilTrip, tripDuration: $tripDuration)';
}


}

/// @nodoc
abstract mixin class _$TripHomeStatsCopyWith<$Res> implements $TripHomeStatsCopyWith<$Res> {
  factory _$TripHomeStatsCopyWith(_TripHomeStats value, $Res Function(_TripHomeStats) _then) = __$TripHomeStatsCopyWithImpl;
@override @useResult
$Res call({
 int baggageCount, double totalExpenses, int nbTravelers, int? daysUntilTrip, int? tripDuration
});




}
/// @nodoc
class __$TripHomeStatsCopyWithImpl<$Res>
    implements _$TripHomeStatsCopyWith<$Res> {
  __$TripHomeStatsCopyWithImpl(this._self, this._then);

  final _TripHomeStats _self;
  final $Res Function(_TripHomeStats) _then;

/// Create a copy of TripHomeStats
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? baggageCount = null,Object? totalExpenses = null,Object? nbTravelers = null,Object? daysUntilTrip = freezed,Object? tripDuration = freezed,}) {
  return _then(_TripHomeStats(
baggageCount: null == baggageCount ? _self.baggageCount : baggageCount // ignore: cast_nullable_to_non_nullable
as int,totalExpenses: null == totalExpenses ? _self.totalExpenses : totalExpenses // ignore: cast_nullable_to_non_nullable
as double,nbTravelers: null == nbTravelers ? _self.nbTravelers : nbTravelers // ignore: cast_nullable_to_non_nullable
as int,daysUntilTrip: freezed == daysUntilTrip ? _self.daysUntilTrip : daysUntilTrip // ignore: cast_nullable_to_non_nullable
as int?,tripDuration: freezed == tripDuration ? _self.tripDuration : tripDuration // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$TripFeatureTile {

 String get id; String get label; String get icon; String get route; bool get enabled;
/// Create a copy of TripFeatureTile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TripFeatureTileCopyWith<TripFeatureTile> get copyWith => _$TripFeatureTileCopyWithImpl<TripFeatureTile>(this as TripFeatureTile, _$identity);

  /// Serializes this TripFeatureTile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TripFeatureTile&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.route, route) || other.route == route)&&(identical(other.enabled, enabled) || other.enabled == enabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,icon,route,enabled);

@override
String toString() {
  return 'TripFeatureTile(id: $id, label: $label, icon: $icon, route: $route, enabled: $enabled)';
}


}

/// @nodoc
abstract mixin class $TripFeatureTileCopyWith<$Res>  {
  factory $TripFeatureTileCopyWith(TripFeatureTile value, $Res Function(TripFeatureTile) _then) = _$TripFeatureTileCopyWithImpl;
@useResult
$Res call({
 String id, String label, String icon, String route, bool enabled
});




}
/// @nodoc
class _$TripFeatureTileCopyWithImpl<$Res>
    implements $TripFeatureTileCopyWith<$Res> {
  _$TripFeatureTileCopyWithImpl(this._self, this._then);

  final TripFeatureTile _self;
  final $Res Function(TripFeatureTile) _then;

/// Create a copy of TripFeatureTile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,Object? icon = null,Object? route = null,Object? enabled = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,route: null == route ? _self.route : route // ignore: cast_nullable_to_non_nullable
as String,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [TripFeatureTile].
extension TripFeatureTilePatterns on TripFeatureTile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TripFeatureTile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TripFeatureTile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TripFeatureTile value)  $default,){
final _that = this;
switch (_that) {
case _TripFeatureTile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TripFeatureTile value)?  $default,){
final _that = this;
switch (_that) {
case _TripFeatureTile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String label,  String icon,  String route,  bool enabled)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TripFeatureTile() when $default != null:
return $default(_that.id,_that.label,_that.icon,_that.route,_that.enabled);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String label,  String icon,  String route,  bool enabled)  $default,) {final _that = this;
switch (_that) {
case _TripFeatureTile():
return $default(_that.id,_that.label,_that.icon,_that.route,_that.enabled);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String label,  String icon,  String route,  bool enabled)?  $default,) {final _that = this;
switch (_that) {
case _TripFeatureTile() when $default != null:
return $default(_that.id,_that.label,_that.icon,_that.route,_that.enabled);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TripFeatureTile implements TripFeatureTile {
  const _TripFeatureTile({required this.id, required this.label, required this.icon, required this.route, this.enabled = false});
  factory _TripFeatureTile.fromJson(Map<String, dynamic> json) => _$TripFeatureTileFromJson(json);

@override final  String id;
@override final  String label;
@override final  String icon;
@override final  String route;
@override@JsonKey() final  bool enabled;

/// Create a copy of TripFeatureTile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TripFeatureTileCopyWith<_TripFeatureTile> get copyWith => __$TripFeatureTileCopyWithImpl<_TripFeatureTile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TripFeatureTileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TripFeatureTile&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.route, route) || other.route == route)&&(identical(other.enabled, enabled) || other.enabled == enabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,icon,route,enabled);

@override
String toString() {
  return 'TripFeatureTile(id: $id, label: $label, icon: $icon, route: $route, enabled: $enabled)';
}


}

/// @nodoc
abstract mixin class _$TripFeatureTileCopyWith<$Res> implements $TripFeatureTileCopyWith<$Res> {
  factory _$TripFeatureTileCopyWith(_TripFeatureTile value, $Res Function(_TripFeatureTile) _then) = __$TripFeatureTileCopyWithImpl;
@override @useResult
$Res call({
 String id, String label, String icon, String route, bool enabled
});




}
/// @nodoc
class __$TripFeatureTileCopyWithImpl<$Res>
    implements _$TripFeatureTileCopyWith<$Res> {
  __$TripFeatureTileCopyWithImpl(this._self, this._then);

  final _TripFeatureTile _self;
  final $Res Function(_TripFeatureTile) _then;

/// Create a copy of TripFeatureTile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,Object? icon = null,Object? route = null,Object? enabled = null,}) {
  return _then(_TripFeatureTile(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,route: null == route ? _self.route : route // ignore: cast_nullable_to_non_nullable
as String,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$TripSectionSummary {

 String get sectionId; int get count; List<String> get previewItems;
/// Create a copy of TripSectionSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TripSectionSummaryCopyWith<TripSectionSummary> get copyWith => _$TripSectionSummaryCopyWithImpl<TripSectionSummary>(this as TripSectionSummary, _$identity);

  /// Serializes this TripSectionSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TripSectionSummary&&(identical(other.sectionId, sectionId) || other.sectionId == sectionId)&&(identical(other.count, count) || other.count == count)&&const DeepCollectionEquality().equals(other.previewItems, previewItems));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sectionId,count,const DeepCollectionEquality().hash(previewItems));

@override
String toString() {
  return 'TripSectionSummary(sectionId: $sectionId, count: $count, previewItems: $previewItems)';
}


}

/// @nodoc
abstract mixin class $TripSectionSummaryCopyWith<$Res>  {
  factory $TripSectionSummaryCopyWith(TripSectionSummary value, $Res Function(TripSectionSummary) _then) = _$TripSectionSummaryCopyWithImpl;
@useResult
$Res call({
 String sectionId, int count, List<String> previewItems
});




}
/// @nodoc
class _$TripSectionSummaryCopyWithImpl<$Res>
    implements $TripSectionSummaryCopyWith<$Res> {
  _$TripSectionSummaryCopyWithImpl(this._self, this._then);

  final TripSectionSummary _self;
  final $Res Function(TripSectionSummary) _then;

/// Create a copy of TripSectionSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sectionId = null,Object? count = null,Object? previewItems = null,}) {
  return _then(_self.copyWith(
sectionId: null == sectionId ? _self.sectionId : sectionId // ignore: cast_nullable_to_non_nullable
as String,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,previewItems: null == previewItems ? _self.previewItems : previewItems // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [TripSectionSummary].
extension TripSectionSummaryPatterns on TripSectionSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TripSectionSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TripSectionSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TripSectionSummary value)  $default,){
final _that = this;
switch (_that) {
case _TripSectionSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TripSectionSummary value)?  $default,){
final _that = this;
switch (_that) {
case _TripSectionSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String sectionId,  int count,  List<String> previewItems)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TripSectionSummary() when $default != null:
return $default(_that.sectionId,_that.count,_that.previewItems);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String sectionId,  int count,  List<String> previewItems)  $default,) {final _that = this;
switch (_that) {
case _TripSectionSummary():
return $default(_that.sectionId,_that.count,_that.previewItems);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String sectionId,  int count,  List<String> previewItems)?  $default,) {final _that = this;
switch (_that) {
case _TripSectionSummary() when $default != null:
return $default(_that.sectionId,_that.count,_that.previewItems);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TripSectionSummary implements TripSectionSummary {
  const _TripSectionSummary({required this.sectionId, this.count = 0, final  List<String> previewItems = const []}): _previewItems = previewItems;
  factory _TripSectionSummary.fromJson(Map<String, dynamic> json) => _$TripSectionSummaryFromJson(json);

@override final  String sectionId;
@override@JsonKey() final  int count;
 final  List<String> _previewItems;
@override@JsonKey() List<String> get previewItems {
  if (_previewItems is EqualUnmodifiableListView) return _previewItems;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_previewItems);
}


/// Create a copy of TripSectionSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TripSectionSummaryCopyWith<_TripSectionSummary> get copyWith => __$TripSectionSummaryCopyWithImpl<_TripSectionSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TripSectionSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TripSectionSummary&&(identical(other.sectionId, sectionId) || other.sectionId == sectionId)&&(identical(other.count, count) || other.count == count)&&const DeepCollectionEquality().equals(other._previewItems, _previewItems));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sectionId,count,const DeepCollectionEquality().hash(_previewItems));

@override
String toString() {
  return 'TripSectionSummary(sectionId: $sectionId, count: $count, previewItems: $previewItems)';
}


}

/// @nodoc
abstract mixin class _$TripSectionSummaryCopyWith<$Res> implements $TripSectionSummaryCopyWith<$Res> {
  factory _$TripSectionSummaryCopyWith(_TripSectionSummary value, $Res Function(_TripSectionSummary) _then) = __$TripSectionSummaryCopyWithImpl;
@override @useResult
$Res call({
 String sectionId, int count, List<String> previewItems
});




}
/// @nodoc
class __$TripSectionSummaryCopyWithImpl<$Res>
    implements _$TripSectionSummaryCopyWith<$Res> {
  __$TripSectionSummaryCopyWithImpl(this._self, this._then);

  final _TripSectionSummary _self;
  final $Res Function(_TripSectionSummary) _then;

/// Create a copy of TripSectionSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sectionId = null,Object? count = null,Object? previewItems = null,}) {
  return _then(_TripSectionSummary(
sectionId: null == sectionId ? _self.sectionId : sectionId // ignore: cast_nullable_to_non_nullable
as String,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,previewItems: null == previewItems ? _self._previewItems : previewItems // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$TripHome {

 Trip get trip; TripHomeStats get stats; List<TripFeatureTile> get features; List<TripSectionSummary> get sections;
/// Create a copy of TripHome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TripHomeCopyWith<TripHome> get copyWith => _$TripHomeCopyWithImpl<TripHome>(this as TripHome, _$identity);

  /// Serializes this TripHome to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TripHome&&(identical(other.trip, trip) || other.trip == trip)&&(identical(other.stats, stats) || other.stats == stats)&&const DeepCollectionEquality().equals(other.features, features)&&const DeepCollectionEquality().equals(other.sections, sections));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,trip,stats,const DeepCollectionEquality().hash(features),const DeepCollectionEquality().hash(sections));

@override
String toString() {
  return 'TripHome(trip: $trip, stats: $stats, features: $features, sections: $sections)';
}


}

/// @nodoc
abstract mixin class $TripHomeCopyWith<$Res>  {
  factory $TripHomeCopyWith(TripHome value, $Res Function(TripHome) _then) = _$TripHomeCopyWithImpl;
@useResult
$Res call({
 Trip trip, TripHomeStats stats, List<TripFeatureTile> features, List<TripSectionSummary> sections
});


$TripCopyWith<$Res> get trip;$TripHomeStatsCopyWith<$Res> get stats;

}
/// @nodoc
class _$TripHomeCopyWithImpl<$Res>
    implements $TripHomeCopyWith<$Res> {
  _$TripHomeCopyWithImpl(this._self, this._then);

  final TripHome _self;
  final $Res Function(TripHome) _then;

/// Create a copy of TripHome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? trip = null,Object? stats = null,Object? features = null,Object? sections = null,}) {
  return _then(_self.copyWith(
trip: null == trip ? _self.trip : trip // ignore: cast_nullable_to_non_nullable
as Trip,stats: null == stats ? _self.stats : stats // ignore: cast_nullable_to_non_nullable
as TripHomeStats,features: null == features ? _self.features : features // ignore: cast_nullable_to_non_nullable
as List<TripFeatureTile>,sections: null == sections ? _self.sections : sections // ignore: cast_nullable_to_non_nullable
as List<TripSectionSummary>,
  ));
}
/// Create a copy of TripHome
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TripCopyWith<$Res> get trip {
  
  return $TripCopyWith<$Res>(_self.trip, (value) {
    return _then(_self.copyWith(trip: value));
  });
}/// Create a copy of TripHome
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TripHomeStatsCopyWith<$Res> get stats {
  
  return $TripHomeStatsCopyWith<$Res>(_self.stats, (value) {
    return _then(_self.copyWith(stats: value));
  });
}
}


/// Adds pattern-matching-related methods to [TripHome].
extension TripHomePatterns on TripHome {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TripHome value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TripHome() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TripHome value)  $default,){
final _that = this;
switch (_that) {
case _TripHome():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TripHome value)?  $default,){
final _that = this;
switch (_that) {
case _TripHome() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Trip trip,  TripHomeStats stats,  List<TripFeatureTile> features,  List<TripSectionSummary> sections)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TripHome() when $default != null:
return $default(_that.trip,_that.stats,_that.features,_that.sections);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Trip trip,  TripHomeStats stats,  List<TripFeatureTile> features,  List<TripSectionSummary> sections)  $default,) {final _that = this;
switch (_that) {
case _TripHome():
return $default(_that.trip,_that.stats,_that.features,_that.sections);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Trip trip,  TripHomeStats stats,  List<TripFeatureTile> features,  List<TripSectionSummary> sections)?  $default,) {final _that = this;
switch (_that) {
case _TripHome() when $default != null:
return $default(_that.trip,_that.stats,_that.features,_that.sections);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TripHome implements TripHome {
  const _TripHome({required this.trip, required this.stats, required final  List<TripFeatureTile> features, final  List<TripSectionSummary> sections = const []}): _features = features,_sections = sections;
  factory _TripHome.fromJson(Map<String, dynamic> json) => _$TripHomeFromJson(json);

@override final  Trip trip;
@override final  TripHomeStats stats;
 final  List<TripFeatureTile> _features;
@override List<TripFeatureTile> get features {
  if (_features is EqualUnmodifiableListView) return _features;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_features);
}

 final  List<TripSectionSummary> _sections;
@override@JsonKey() List<TripSectionSummary> get sections {
  if (_sections is EqualUnmodifiableListView) return _sections;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sections);
}


/// Create a copy of TripHome
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TripHomeCopyWith<_TripHome> get copyWith => __$TripHomeCopyWithImpl<_TripHome>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TripHomeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TripHome&&(identical(other.trip, trip) || other.trip == trip)&&(identical(other.stats, stats) || other.stats == stats)&&const DeepCollectionEquality().equals(other._features, _features)&&const DeepCollectionEquality().equals(other._sections, _sections));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,trip,stats,const DeepCollectionEquality().hash(_features),const DeepCollectionEquality().hash(_sections));

@override
String toString() {
  return 'TripHome(trip: $trip, stats: $stats, features: $features, sections: $sections)';
}


}

/// @nodoc
abstract mixin class _$TripHomeCopyWith<$Res> implements $TripHomeCopyWith<$Res> {
  factory _$TripHomeCopyWith(_TripHome value, $Res Function(_TripHome) _then) = __$TripHomeCopyWithImpl;
@override @useResult
$Res call({
 Trip trip, TripHomeStats stats, List<TripFeatureTile> features, List<TripSectionSummary> sections
});


@override $TripCopyWith<$Res> get trip;@override $TripHomeStatsCopyWith<$Res> get stats;

}
/// @nodoc
class __$TripHomeCopyWithImpl<$Res>
    implements _$TripHomeCopyWith<$Res> {
  __$TripHomeCopyWithImpl(this._self, this._then);

  final _TripHome _self;
  final $Res Function(_TripHome) _then;

/// Create a copy of TripHome
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? trip = null,Object? stats = null,Object? features = null,Object? sections = null,}) {
  return _then(_TripHome(
trip: null == trip ? _self.trip : trip // ignore: cast_nullable_to_non_nullable
as Trip,stats: null == stats ? _self.stats : stats // ignore: cast_nullable_to_non_nullable
as TripHomeStats,features: null == features ? _self._features : features // ignore: cast_nullable_to_non_nullable
as List<TripFeatureTile>,sections: null == sections ? _self._sections : sections // ignore: cast_nullable_to_non_nullable
as List<TripSectionSummary>,
  ));
}

/// Create a copy of TripHome
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TripCopyWith<$Res> get trip {
  
  return $TripCopyWith<$Res>(_self.trip, (value) {
    return _then(_self.copyWith(trip: value));
  });
}/// Create a copy of TripHome
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TripHomeStatsCopyWith<$Res> get stats {
  
  return $TripHomeStatsCopyWith<$Res>(_self.stats, (value) {
    return _then(_self.copyWith(stats: value));
  });
}
}

// dart format on
