// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'traveler.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Traveler {

 String get id; String get tripId; String? get amadeusTravelerRef; String get travelerType; String get firstName; String get lastName; DateTime? get dateOfBirth; String? get gender; List<Map<String, dynamic>>? get documents; Map<String, dynamic>? get contacts; DateTime? get createdAt; DateTime? get updatedAt;
/// Create a copy of Traveler
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TravelerCopyWith<Traveler> get copyWith => _$TravelerCopyWithImpl<Traveler>(this as Traveler, _$identity);

  /// Serializes this Traveler to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Traveler&&(identical(other.id, id) || other.id == id)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.amadeusTravelerRef, amadeusTravelerRef) || other.amadeusTravelerRef == amadeusTravelerRef)&&(identical(other.travelerType, travelerType) || other.travelerType == travelerType)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.dateOfBirth, dateOfBirth) || other.dateOfBirth == dateOfBirth)&&(identical(other.gender, gender) || other.gender == gender)&&const DeepCollectionEquality().equals(other.documents, documents)&&const DeepCollectionEquality().equals(other.contacts, contacts)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tripId,amadeusTravelerRef,travelerType,firstName,lastName,dateOfBirth,gender,const DeepCollectionEquality().hash(documents),const DeepCollectionEquality().hash(contacts),createdAt,updatedAt);

@override
String toString() {
  return 'Traveler(id: $id, tripId: $tripId, amadeusTravelerRef: $amadeusTravelerRef, travelerType: $travelerType, firstName: $firstName, lastName: $lastName, dateOfBirth: $dateOfBirth, gender: $gender, documents: $documents, contacts: $contacts, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $TravelerCopyWith<$Res>  {
  factory $TravelerCopyWith(Traveler value, $Res Function(Traveler) _then) = _$TravelerCopyWithImpl;
@useResult
$Res call({
 String id, String tripId, String? amadeusTravelerRef, String travelerType, String firstName, String lastName, DateTime? dateOfBirth, String? gender, List<Map<String, dynamic>>? documents, Map<String, dynamic>? contacts, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class _$TravelerCopyWithImpl<$Res>
    implements $TravelerCopyWith<$Res> {
  _$TravelerCopyWithImpl(this._self, this._then);

  final Traveler _self;
  final $Res Function(Traveler) _then;

/// Create a copy of Traveler
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? tripId = null,Object? amadeusTravelerRef = freezed,Object? travelerType = null,Object? firstName = null,Object? lastName = null,Object? dateOfBirth = freezed,Object? gender = freezed,Object? documents = freezed,Object? contacts = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,amadeusTravelerRef: freezed == amadeusTravelerRef ? _self.amadeusTravelerRef : amadeusTravelerRef // ignore: cast_nullable_to_non_nullable
as String?,travelerType: null == travelerType ? _self.travelerType : travelerType // ignore: cast_nullable_to_non_nullable
as String,firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,lastName: null == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String,dateOfBirth: freezed == dateOfBirth ? _self.dateOfBirth : dateOfBirth // ignore: cast_nullable_to_non_nullable
as DateTime?,gender: freezed == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String?,documents: freezed == documents ? _self.documents : documents // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>?,contacts: freezed == contacts ? _self.contacts : contacts // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Traveler].
extension TravelerPatterns on Traveler {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Traveler value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Traveler() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Traveler value)  $default,){
final _that = this;
switch (_that) {
case _Traveler():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Traveler value)?  $default,){
final _that = this;
switch (_that) {
case _Traveler() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String tripId,  String? amadeusTravelerRef,  String travelerType,  String firstName,  String lastName,  DateTime? dateOfBirth,  String? gender,  List<Map<String, dynamic>>? documents,  Map<String, dynamic>? contacts,  DateTime? createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Traveler() when $default != null:
return $default(_that.id,_that.tripId,_that.amadeusTravelerRef,_that.travelerType,_that.firstName,_that.lastName,_that.dateOfBirth,_that.gender,_that.documents,_that.contacts,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String tripId,  String? amadeusTravelerRef,  String travelerType,  String firstName,  String lastName,  DateTime? dateOfBirth,  String? gender,  List<Map<String, dynamic>>? documents,  Map<String, dynamic>? contacts,  DateTime? createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Traveler():
return $default(_that.id,_that.tripId,_that.amadeusTravelerRef,_that.travelerType,_that.firstName,_that.lastName,_that.dateOfBirth,_that.gender,_that.documents,_that.contacts,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String tripId,  String? amadeusTravelerRef,  String travelerType,  String firstName,  String lastName,  DateTime? dateOfBirth,  String? gender,  List<Map<String, dynamic>>? documents,  Map<String, dynamic>? contacts,  DateTime? createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Traveler() when $default != null:
return $default(_that.id,_that.tripId,_that.amadeusTravelerRef,_that.travelerType,_that.firstName,_that.lastName,_that.dateOfBirth,_that.gender,_that.documents,_that.contacts,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Traveler implements Traveler {
  const _Traveler({required this.id, required this.tripId, this.amadeusTravelerRef, this.travelerType = 'ADULT', required this.firstName, required this.lastName, this.dateOfBirth, this.gender, final  List<Map<String, dynamic>>? documents, final  Map<String, dynamic>? contacts, this.createdAt, this.updatedAt}): _documents = documents,_contacts = contacts;
  factory _Traveler.fromJson(Map<String, dynamic> json) => _$TravelerFromJson(json);

@override final  String id;
@override final  String tripId;
@override final  String? amadeusTravelerRef;
@override@JsonKey() final  String travelerType;
@override final  String firstName;
@override final  String lastName;
@override final  DateTime? dateOfBirth;
@override final  String? gender;
 final  List<Map<String, dynamic>>? _documents;
@override List<Map<String, dynamic>>? get documents {
  final value = _documents;
  if (value == null) return null;
  if (_documents is EqualUnmodifiableListView) return _documents;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  Map<String, dynamic>? _contacts;
@override Map<String, dynamic>? get contacts {
  final value = _contacts;
  if (value == null) return null;
  if (_contacts is EqualUnmodifiableMapView) return _contacts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;

/// Create a copy of Traveler
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TravelerCopyWith<_Traveler> get copyWith => __$TravelerCopyWithImpl<_Traveler>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TravelerToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Traveler&&(identical(other.id, id) || other.id == id)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.amadeusTravelerRef, amadeusTravelerRef) || other.amadeusTravelerRef == amadeusTravelerRef)&&(identical(other.travelerType, travelerType) || other.travelerType == travelerType)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.dateOfBirth, dateOfBirth) || other.dateOfBirth == dateOfBirth)&&(identical(other.gender, gender) || other.gender == gender)&&const DeepCollectionEquality().equals(other._documents, _documents)&&const DeepCollectionEquality().equals(other._contacts, _contacts)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tripId,amadeusTravelerRef,travelerType,firstName,lastName,dateOfBirth,gender,const DeepCollectionEquality().hash(_documents),const DeepCollectionEquality().hash(_contacts),createdAt,updatedAt);

@override
String toString() {
  return 'Traveler(id: $id, tripId: $tripId, amadeusTravelerRef: $amadeusTravelerRef, travelerType: $travelerType, firstName: $firstName, lastName: $lastName, dateOfBirth: $dateOfBirth, gender: $gender, documents: $documents, contacts: $contacts, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$TravelerCopyWith<$Res> implements $TravelerCopyWith<$Res> {
  factory _$TravelerCopyWith(_Traveler value, $Res Function(_Traveler) _then) = __$TravelerCopyWithImpl;
@override @useResult
$Res call({
 String id, String tripId, String? amadeusTravelerRef, String travelerType, String firstName, String lastName, DateTime? dateOfBirth, String? gender, List<Map<String, dynamic>>? documents, Map<String, dynamic>? contacts, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class __$TravelerCopyWithImpl<$Res>
    implements _$TravelerCopyWith<$Res> {
  __$TravelerCopyWithImpl(this._self, this._then);

  final _Traveler _self;
  final $Res Function(_Traveler) _then;

/// Create a copy of Traveler
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tripId = null,Object? amadeusTravelerRef = freezed,Object? travelerType = null,Object? firstName = null,Object? lastName = null,Object? dateOfBirth = freezed,Object? gender = freezed,Object? documents = freezed,Object? contacts = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_Traveler(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,amadeusTravelerRef: freezed == amadeusTravelerRef ? _self.amadeusTravelerRef : amadeusTravelerRef // ignore: cast_nullable_to_non_nullable
as String?,travelerType: null == travelerType ? _self.travelerType : travelerType // ignore: cast_nullable_to_non_nullable
as String,firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,lastName: null == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String,dateOfBirth: freezed == dateOfBirth ? _self.dateOfBirth : dateOfBirth // ignore: cast_nullable_to_non_nullable
as DateTime?,gender: freezed == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String?,documents: freezed == documents ? _self._documents : documents // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>?,contacts: freezed == contacts ? _self._contacts : contacts // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
