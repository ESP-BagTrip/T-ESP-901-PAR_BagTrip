// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'traveler_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TravelerProfile {

 String get id;@JsonKey(name: 'travelTypes') List<String> get travelTypes;@JsonKey(name: 'travelStyle') String? get travelStyle; String? get budget; String? get companions;@JsonKey(name: 'travelFrequency') String? get travelFrequency;@JsonKey(name: 'medicalConstraints') String? get medicalConstraints;@JsonKey(name: 'isCompleted') bool get isCompleted;@JsonKey(name: 'createdAt') DateTime? get createdAt;@JsonKey(name: 'updatedAt') DateTime? get updatedAt;
/// Create a copy of TravelerProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TravelerProfileCopyWith<TravelerProfile> get copyWith => _$TravelerProfileCopyWithImpl<TravelerProfile>(this as TravelerProfile, _$identity);

  /// Serializes this TravelerProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TravelerProfile&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other.travelTypes, travelTypes)&&(identical(other.travelStyle, travelStyle) || other.travelStyle == travelStyle)&&(identical(other.budget, budget) || other.budget == budget)&&(identical(other.companions, companions) || other.companions == companions)&&(identical(other.travelFrequency, travelFrequency) || other.travelFrequency == travelFrequency)&&(identical(other.medicalConstraints, medicalConstraints) || other.medicalConstraints == medicalConstraints)&&(identical(other.isCompleted, isCompleted) || other.isCompleted == isCompleted)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,const DeepCollectionEquality().hash(travelTypes),travelStyle,budget,companions,travelFrequency,medicalConstraints,isCompleted,createdAt,updatedAt);

@override
String toString() {
  return 'TravelerProfile(id: $id, travelTypes: $travelTypes, travelStyle: $travelStyle, budget: $budget, companions: $companions, travelFrequency: $travelFrequency, medicalConstraints: $medicalConstraints, isCompleted: $isCompleted, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $TravelerProfileCopyWith<$Res>  {
  factory $TravelerProfileCopyWith(TravelerProfile value, $Res Function(TravelerProfile) _then) = _$TravelerProfileCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'travelTypes') List<String> travelTypes,@JsonKey(name: 'travelStyle') String? travelStyle, String? budget, String? companions,@JsonKey(name: 'travelFrequency') String? travelFrequency,@JsonKey(name: 'medicalConstraints') String? medicalConstraints,@JsonKey(name: 'isCompleted') bool isCompleted,@JsonKey(name: 'createdAt') DateTime? createdAt,@JsonKey(name: 'updatedAt') DateTime? updatedAt
});




}
/// @nodoc
class _$TravelerProfileCopyWithImpl<$Res>
    implements $TravelerProfileCopyWith<$Res> {
  _$TravelerProfileCopyWithImpl(this._self, this._then);

  final TravelerProfile _self;
  final $Res Function(TravelerProfile) _then;

/// Create a copy of TravelerProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? travelTypes = null,Object? travelStyle = freezed,Object? budget = freezed,Object? companions = freezed,Object? travelFrequency = freezed,Object? medicalConstraints = freezed,Object? isCompleted = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,travelTypes: null == travelTypes ? _self.travelTypes : travelTypes // ignore: cast_nullable_to_non_nullable
as List<String>,travelStyle: freezed == travelStyle ? _self.travelStyle : travelStyle // ignore: cast_nullable_to_non_nullable
as String?,budget: freezed == budget ? _self.budget : budget // ignore: cast_nullable_to_non_nullable
as String?,companions: freezed == companions ? _self.companions : companions // ignore: cast_nullable_to_non_nullable
as String?,travelFrequency: freezed == travelFrequency ? _self.travelFrequency : travelFrequency // ignore: cast_nullable_to_non_nullable
as String?,medicalConstraints: freezed == medicalConstraints ? _self.medicalConstraints : medicalConstraints // ignore: cast_nullable_to_non_nullable
as String?,isCompleted: null == isCompleted ? _self.isCompleted : isCompleted // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [TravelerProfile].
extension TravelerProfilePatterns on TravelerProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TravelerProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TravelerProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TravelerProfile value)  $default,){
final _that = this;
switch (_that) {
case _TravelerProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TravelerProfile value)?  $default,){
final _that = this;
switch (_that) {
case _TravelerProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'travelTypes')  List<String> travelTypes, @JsonKey(name: 'travelStyle')  String? travelStyle,  String? budget,  String? companions, @JsonKey(name: 'travelFrequency')  String? travelFrequency, @JsonKey(name: 'medicalConstraints')  String? medicalConstraints, @JsonKey(name: 'isCompleted')  bool isCompleted, @JsonKey(name: 'createdAt')  DateTime? createdAt, @JsonKey(name: 'updatedAt')  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TravelerProfile() when $default != null:
return $default(_that.id,_that.travelTypes,_that.travelStyle,_that.budget,_that.companions,_that.travelFrequency,_that.medicalConstraints,_that.isCompleted,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'travelTypes')  List<String> travelTypes, @JsonKey(name: 'travelStyle')  String? travelStyle,  String? budget,  String? companions, @JsonKey(name: 'travelFrequency')  String? travelFrequency, @JsonKey(name: 'medicalConstraints')  String? medicalConstraints, @JsonKey(name: 'isCompleted')  bool isCompleted, @JsonKey(name: 'createdAt')  DateTime? createdAt, @JsonKey(name: 'updatedAt')  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _TravelerProfile():
return $default(_that.id,_that.travelTypes,_that.travelStyle,_that.budget,_that.companions,_that.travelFrequency,_that.medicalConstraints,_that.isCompleted,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'travelTypes')  List<String> travelTypes, @JsonKey(name: 'travelStyle')  String? travelStyle,  String? budget,  String? companions, @JsonKey(name: 'travelFrequency')  String? travelFrequency, @JsonKey(name: 'medicalConstraints')  String? medicalConstraints, @JsonKey(name: 'isCompleted')  bool isCompleted, @JsonKey(name: 'createdAt')  DateTime? createdAt, @JsonKey(name: 'updatedAt')  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _TravelerProfile() when $default != null:
return $default(_that.id,_that.travelTypes,_that.travelStyle,_that.budget,_that.companions,_that.travelFrequency,_that.medicalConstraints,_that.isCompleted,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TravelerProfile implements TravelerProfile {
  const _TravelerProfile({required this.id, @JsonKey(name: 'travelTypes') final  List<String> travelTypes = const [], @JsonKey(name: 'travelStyle') this.travelStyle, this.budget, this.companions, @JsonKey(name: 'travelFrequency') this.travelFrequency, @JsonKey(name: 'medicalConstraints') this.medicalConstraints, @JsonKey(name: 'isCompleted') this.isCompleted = false, @JsonKey(name: 'createdAt') this.createdAt, @JsonKey(name: 'updatedAt') this.updatedAt}): _travelTypes = travelTypes;
  factory _TravelerProfile.fromJson(Map<String, dynamic> json) => _$TravelerProfileFromJson(json);

@override final  String id;
 final  List<String> _travelTypes;
@override@JsonKey(name: 'travelTypes') List<String> get travelTypes {
  if (_travelTypes is EqualUnmodifiableListView) return _travelTypes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_travelTypes);
}

@override@JsonKey(name: 'travelStyle') final  String? travelStyle;
@override final  String? budget;
@override final  String? companions;
@override@JsonKey(name: 'travelFrequency') final  String? travelFrequency;
@override@JsonKey(name: 'medicalConstraints') final  String? medicalConstraints;
@override@JsonKey(name: 'isCompleted') final  bool isCompleted;
@override@JsonKey(name: 'createdAt') final  DateTime? createdAt;
@override@JsonKey(name: 'updatedAt') final  DateTime? updatedAt;

/// Create a copy of TravelerProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TravelerProfileCopyWith<_TravelerProfile> get copyWith => __$TravelerProfileCopyWithImpl<_TravelerProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TravelerProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TravelerProfile&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other._travelTypes, _travelTypes)&&(identical(other.travelStyle, travelStyle) || other.travelStyle == travelStyle)&&(identical(other.budget, budget) || other.budget == budget)&&(identical(other.companions, companions) || other.companions == companions)&&(identical(other.travelFrequency, travelFrequency) || other.travelFrequency == travelFrequency)&&(identical(other.medicalConstraints, medicalConstraints) || other.medicalConstraints == medicalConstraints)&&(identical(other.isCompleted, isCompleted) || other.isCompleted == isCompleted)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,const DeepCollectionEquality().hash(_travelTypes),travelStyle,budget,companions,travelFrequency,medicalConstraints,isCompleted,createdAt,updatedAt);

@override
String toString() {
  return 'TravelerProfile(id: $id, travelTypes: $travelTypes, travelStyle: $travelStyle, budget: $budget, companions: $companions, travelFrequency: $travelFrequency, medicalConstraints: $medicalConstraints, isCompleted: $isCompleted, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$TravelerProfileCopyWith<$Res> implements $TravelerProfileCopyWith<$Res> {
  factory _$TravelerProfileCopyWith(_TravelerProfile value, $Res Function(_TravelerProfile) _then) = __$TravelerProfileCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'travelTypes') List<String> travelTypes,@JsonKey(name: 'travelStyle') String? travelStyle, String? budget, String? companions,@JsonKey(name: 'travelFrequency') String? travelFrequency,@JsonKey(name: 'medicalConstraints') String? medicalConstraints,@JsonKey(name: 'isCompleted') bool isCompleted,@JsonKey(name: 'createdAt') DateTime? createdAt,@JsonKey(name: 'updatedAt') DateTime? updatedAt
});




}
/// @nodoc
class __$TravelerProfileCopyWithImpl<$Res>
    implements _$TravelerProfileCopyWith<$Res> {
  __$TravelerProfileCopyWithImpl(this._self, this._then);

  final _TravelerProfile _self;
  final $Res Function(_TravelerProfile) _then;

/// Create a copy of TravelerProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? travelTypes = null,Object? travelStyle = freezed,Object? budget = freezed,Object? companions = freezed,Object? travelFrequency = freezed,Object? medicalConstraints = freezed,Object? isCompleted = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_TravelerProfile(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,travelTypes: null == travelTypes ? _self._travelTypes : travelTypes // ignore: cast_nullable_to_non_nullable
as List<String>,travelStyle: freezed == travelStyle ? _self.travelStyle : travelStyle // ignore: cast_nullable_to_non_nullable
as String?,budget: freezed == budget ? _self.budget : budget // ignore: cast_nullable_to_non_nullable
as String?,companions: freezed == companions ? _self.companions : companions // ignore: cast_nullable_to_non_nullable
as String?,travelFrequency: freezed == travelFrequency ? _self.travelFrequency : travelFrequency // ignore: cast_nullable_to_non_nullable
as String?,medicalConstraints: freezed == medicalConstraints ? _self.medicalConstraints : medicalConstraints // ignore: cast_nullable_to_non_nullable
as String?,isCompleted: null == isCompleted ? _self.isCompleted : isCompleted // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$ProfileCompletion {

@JsonKey(name: 'isCompleted') bool get isCompleted;@JsonKey(name: 'missingFields') List<String> get missingFields;
/// Create a copy of ProfileCompletion
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfileCompletionCopyWith<ProfileCompletion> get copyWith => _$ProfileCompletionCopyWithImpl<ProfileCompletion>(this as ProfileCompletion, _$identity);

  /// Serializes this ProfileCompletion to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfileCompletion&&(identical(other.isCompleted, isCompleted) || other.isCompleted == isCompleted)&&const DeepCollectionEquality().equals(other.missingFields, missingFields));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isCompleted,const DeepCollectionEquality().hash(missingFields));

@override
String toString() {
  return 'ProfileCompletion(isCompleted: $isCompleted, missingFields: $missingFields)';
}


}

/// @nodoc
abstract mixin class $ProfileCompletionCopyWith<$Res>  {
  factory $ProfileCompletionCopyWith(ProfileCompletion value, $Res Function(ProfileCompletion) _then) = _$ProfileCompletionCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'isCompleted') bool isCompleted,@JsonKey(name: 'missingFields') List<String> missingFields
});




}
/// @nodoc
class _$ProfileCompletionCopyWithImpl<$Res>
    implements $ProfileCompletionCopyWith<$Res> {
  _$ProfileCompletionCopyWithImpl(this._self, this._then);

  final ProfileCompletion _self;
  final $Res Function(ProfileCompletion) _then;

/// Create a copy of ProfileCompletion
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isCompleted = null,Object? missingFields = null,}) {
  return _then(_self.copyWith(
isCompleted: null == isCompleted ? _self.isCompleted : isCompleted // ignore: cast_nullable_to_non_nullable
as bool,missingFields: null == missingFields ? _self.missingFields : missingFields // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [ProfileCompletion].
extension ProfileCompletionPatterns on ProfileCompletion {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProfileCompletion value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProfileCompletion() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProfileCompletion value)  $default,){
final _that = this;
switch (_that) {
case _ProfileCompletion():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProfileCompletion value)?  $default,){
final _that = this;
switch (_that) {
case _ProfileCompletion() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'isCompleted')  bool isCompleted, @JsonKey(name: 'missingFields')  List<String> missingFields)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProfileCompletion() when $default != null:
return $default(_that.isCompleted,_that.missingFields);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'isCompleted')  bool isCompleted, @JsonKey(name: 'missingFields')  List<String> missingFields)  $default,) {final _that = this;
switch (_that) {
case _ProfileCompletion():
return $default(_that.isCompleted,_that.missingFields);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'isCompleted')  bool isCompleted, @JsonKey(name: 'missingFields')  List<String> missingFields)?  $default,) {final _that = this;
switch (_that) {
case _ProfileCompletion() when $default != null:
return $default(_that.isCompleted,_that.missingFields);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProfileCompletion implements ProfileCompletion {
  const _ProfileCompletion({@JsonKey(name: 'isCompleted') this.isCompleted = false, @JsonKey(name: 'missingFields') final  List<String> missingFields = const []}): _missingFields = missingFields;
  factory _ProfileCompletion.fromJson(Map<String, dynamic> json) => _$ProfileCompletionFromJson(json);

@override@JsonKey(name: 'isCompleted') final  bool isCompleted;
 final  List<String> _missingFields;
@override@JsonKey(name: 'missingFields') List<String> get missingFields {
  if (_missingFields is EqualUnmodifiableListView) return _missingFields;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_missingFields);
}


/// Create a copy of ProfileCompletion
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfileCompletionCopyWith<_ProfileCompletion> get copyWith => __$ProfileCompletionCopyWithImpl<_ProfileCompletion>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProfileCompletionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProfileCompletion&&(identical(other.isCompleted, isCompleted) || other.isCompleted == isCompleted)&&const DeepCollectionEquality().equals(other._missingFields, _missingFields));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isCompleted,const DeepCollectionEquality().hash(_missingFields));

@override
String toString() {
  return 'ProfileCompletion(isCompleted: $isCompleted, missingFields: $missingFields)';
}


}

/// @nodoc
abstract mixin class _$ProfileCompletionCopyWith<$Res> implements $ProfileCompletionCopyWith<$Res> {
  factory _$ProfileCompletionCopyWith(_ProfileCompletion value, $Res Function(_ProfileCompletion) _then) = __$ProfileCompletionCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'isCompleted') bool isCompleted,@JsonKey(name: 'missingFields') List<String> missingFields
});




}
/// @nodoc
class __$ProfileCompletionCopyWithImpl<$Res>
    implements _$ProfileCompletionCopyWith<$Res> {
  __$ProfileCompletionCopyWithImpl(this._self, this._then);

  final _ProfileCompletion _self;
  final $Res Function(_ProfileCompletion) _then;

/// Create a copy of ProfileCompletion
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isCompleted = null,Object? missingFields = null,}) {
  return _then(_ProfileCompletion(
isCompleted: null == isCompleted ? _self.isCompleted : isCompleted // ignore: cast_nullable_to_non_nullable
as bool,missingFields: null == missingFields ? _self._missingFields : missingFields // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
