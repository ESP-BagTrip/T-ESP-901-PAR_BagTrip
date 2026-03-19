// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ai_trip_proposal.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AiTripProposal {

 String get id; String get destination;@JsonKey(name: 'destinationCountry') String get destinationCountry;@JsonKey(name: 'durationDays') int get durationDays;@JsonKey(name: 'budgetEur') int get priceEur; String get description; List<Map<String, dynamic>> get activities;@JsonKey(name: 'matchReason') String? get matchReason;
/// Create a copy of AiTripProposal
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AiTripProposalCopyWith<AiTripProposal> get copyWith => _$AiTripProposalCopyWithImpl<AiTripProposal>(this as AiTripProposal, _$identity);

  /// Serializes this AiTripProposal to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AiTripProposal&&(identical(other.id, id) || other.id == id)&&(identical(other.destination, destination) || other.destination == destination)&&(identical(other.destinationCountry, destinationCountry) || other.destinationCountry == destinationCountry)&&(identical(other.durationDays, durationDays) || other.durationDays == durationDays)&&(identical(other.priceEur, priceEur) || other.priceEur == priceEur)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.activities, activities)&&(identical(other.matchReason, matchReason) || other.matchReason == matchReason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,destination,destinationCountry,durationDays,priceEur,description,const DeepCollectionEquality().hash(activities),matchReason);

@override
String toString() {
  return 'AiTripProposal(id: $id, destination: $destination, destinationCountry: $destinationCountry, durationDays: $durationDays, priceEur: $priceEur, description: $description, activities: $activities, matchReason: $matchReason)';
}


}

/// @nodoc
abstract mixin class $AiTripProposalCopyWith<$Res>  {
  factory $AiTripProposalCopyWith(AiTripProposal value, $Res Function(AiTripProposal) _then) = _$AiTripProposalCopyWithImpl;
@useResult
$Res call({
 String id, String destination,@JsonKey(name: 'destinationCountry') String destinationCountry,@JsonKey(name: 'durationDays') int durationDays,@JsonKey(name: 'budgetEur') int priceEur, String description, List<Map<String, dynamic>> activities,@JsonKey(name: 'matchReason') String? matchReason
});




}
/// @nodoc
class _$AiTripProposalCopyWithImpl<$Res>
    implements $AiTripProposalCopyWith<$Res> {
  _$AiTripProposalCopyWithImpl(this._self, this._then);

  final AiTripProposal _self;
  final $Res Function(AiTripProposal) _then;

/// Create a copy of AiTripProposal
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? destination = null,Object? destinationCountry = null,Object? durationDays = null,Object? priceEur = null,Object? description = null,Object? activities = null,Object? matchReason = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,destination: null == destination ? _self.destination : destination // ignore: cast_nullable_to_non_nullable
as String,destinationCountry: null == destinationCountry ? _self.destinationCountry : destinationCountry // ignore: cast_nullable_to_non_nullable
as String,durationDays: null == durationDays ? _self.durationDays : durationDays // ignore: cast_nullable_to_non_nullable
as int,priceEur: null == priceEur ? _self.priceEur : priceEur // ignore: cast_nullable_to_non_nullable
as int,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,activities: null == activities ? _self.activities : activities // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,matchReason: freezed == matchReason ? _self.matchReason : matchReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AiTripProposal].
extension AiTripProposalPatterns on AiTripProposal {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AiTripProposal value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AiTripProposal() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AiTripProposal value)  $default,){
final _that = this;
switch (_that) {
case _AiTripProposal():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AiTripProposal value)?  $default,){
final _that = this;
switch (_that) {
case _AiTripProposal() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String destination, @JsonKey(name: 'destinationCountry')  String destinationCountry, @JsonKey(name: 'durationDays')  int durationDays, @JsonKey(name: 'budgetEur')  int priceEur,  String description,  List<Map<String, dynamic>> activities, @JsonKey(name: 'matchReason')  String? matchReason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AiTripProposal() when $default != null:
return $default(_that.id,_that.destination,_that.destinationCountry,_that.durationDays,_that.priceEur,_that.description,_that.activities,_that.matchReason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String destination, @JsonKey(name: 'destinationCountry')  String destinationCountry, @JsonKey(name: 'durationDays')  int durationDays, @JsonKey(name: 'budgetEur')  int priceEur,  String description,  List<Map<String, dynamic>> activities, @JsonKey(name: 'matchReason')  String? matchReason)  $default,) {final _that = this;
switch (_that) {
case _AiTripProposal():
return $default(_that.id,_that.destination,_that.destinationCountry,_that.durationDays,_that.priceEur,_that.description,_that.activities,_that.matchReason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String destination, @JsonKey(name: 'destinationCountry')  String destinationCountry, @JsonKey(name: 'durationDays')  int durationDays, @JsonKey(name: 'budgetEur')  int priceEur,  String description,  List<Map<String, dynamic>> activities, @JsonKey(name: 'matchReason')  String? matchReason)?  $default,) {final _that = this;
switch (_that) {
case _AiTripProposal() when $default != null:
return $default(_that.id,_that.destination,_that.destinationCountry,_that.durationDays,_that.priceEur,_that.description,_that.activities,_that.matchReason);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AiTripProposal implements AiTripProposal {
  const _AiTripProposal({this.id = '', this.destination = '', @JsonKey(name: 'destinationCountry') this.destinationCountry = '', @JsonKey(name: 'durationDays') this.durationDays = 0, @JsonKey(name: 'budgetEur') this.priceEur = 0, this.description = '', final  List<Map<String, dynamic>> activities = const [], @JsonKey(name: 'matchReason') this.matchReason}): _activities = activities;
  factory _AiTripProposal.fromJson(Map<String, dynamic> json) => _$AiTripProposalFromJson(json);

@override@JsonKey() final  String id;
@override@JsonKey() final  String destination;
@override@JsonKey(name: 'destinationCountry') final  String destinationCountry;
@override@JsonKey(name: 'durationDays') final  int durationDays;
@override@JsonKey(name: 'budgetEur') final  int priceEur;
@override@JsonKey() final  String description;
 final  List<Map<String, dynamic>> _activities;
@override@JsonKey() List<Map<String, dynamic>> get activities {
  if (_activities is EqualUnmodifiableListView) return _activities;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_activities);
}

@override@JsonKey(name: 'matchReason') final  String? matchReason;

/// Create a copy of AiTripProposal
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AiTripProposalCopyWith<_AiTripProposal> get copyWith => __$AiTripProposalCopyWithImpl<_AiTripProposal>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AiTripProposalToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AiTripProposal&&(identical(other.id, id) || other.id == id)&&(identical(other.destination, destination) || other.destination == destination)&&(identical(other.destinationCountry, destinationCountry) || other.destinationCountry == destinationCountry)&&(identical(other.durationDays, durationDays) || other.durationDays == durationDays)&&(identical(other.priceEur, priceEur) || other.priceEur == priceEur)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other._activities, _activities)&&(identical(other.matchReason, matchReason) || other.matchReason == matchReason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,destination,destinationCountry,durationDays,priceEur,description,const DeepCollectionEquality().hash(_activities),matchReason);

@override
String toString() {
  return 'AiTripProposal(id: $id, destination: $destination, destinationCountry: $destinationCountry, durationDays: $durationDays, priceEur: $priceEur, description: $description, activities: $activities, matchReason: $matchReason)';
}


}

/// @nodoc
abstract mixin class _$AiTripProposalCopyWith<$Res> implements $AiTripProposalCopyWith<$Res> {
  factory _$AiTripProposalCopyWith(_AiTripProposal value, $Res Function(_AiTripProposal) _then) = __$AiTripProposalCopyWithImpl;
@override @useResult
$Res call({
 String id, String destination,@JsonKey(name: 'destinationCountry') String destinationCountry,@JsonKey(name: 'durationDays') int durationDays,@JsonKey(name: 'budgetEur') int priceEur, String description, List<Map<String, dynamic>> activities,@JsonKey(name: 'matchReason') String? matchReason
});




}
/// @nodoc
class __$AiTripProposalCopyWithImpl<$Res>
    implements _$AiTripProposalCopyWith<$Res> {
  __$AiTripProposalCopyWithImpl(this._self, this._then);

  final _AiTripProposal _self;
  final $Res Function(_AiTripProposal) _then;

/// Create a copy of AiTripProposal
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? destination = null,Object? destinationCountry = null,Object? durationDays = null,Object? priceEur = null,Object? description = null,Object? activities = null,Object? matchReason = freezed,}) {
  return _then(_AiTripProposal(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,destination: null == destination ? _self.destination : destination // ignore: cast_nullable_to_non_nullable
as String,destinationCountry: null == destinationCountry ? _self.destinationCountry : destinationCountry // ignore: cast_nullable_to_non_nullable
as String,durationDays: null == durationDays ? _self.durationDays : durationDays // ignore: cast_nullable_to_non_nullable
as int,priceEur: null == priceEur ? _self.priceEur : priceEur // ignore: cast_nullable_to_non_nullable
as int,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,activities: null == activities ? _self._activities : activities // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,matchReason: freezed == matchReason ? _self.matchReason : matchReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
