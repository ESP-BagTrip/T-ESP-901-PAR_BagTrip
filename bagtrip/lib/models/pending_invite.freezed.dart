// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pending_invite.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PendingInvite {

 String get id;@JsonKey(name: 'trip_id') String get tripId; String get email; String get role; String get token;@JsonKey(name: 'created_at') DateTime? get createdAt;@JsonKey(name: 'expires_at') DateTime? get expiresAt;
/// Create a copy of PendingInvite
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PendingInviteCopyWith<PendingInvite> get copyWith => _$PendingInviteCopyWithImpl<PendingInvite>(this as PendingInvite, _$identity);

  /// Serializes this PendingInvite to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PendingInvite&&(identical(other.id, id) || other.id == id)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.email, email) || other.email == email)&&(identical(other.role, role) || other.role == role)&&(identical(other.token, token) || other.token == token)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tripId,email,role,token,createdAt,expiresAt);

@override
String toString() {
  return 'PendingInvite(id: $id, tripId: $tripId, email: $email, role: $role, token: $token, createdAt: $createdAt, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class $PendingInviteCopyWith<$Res>  {
  factory $PendingInviteCopyWith(PendingInvite value, $Res Function(PendingInvite) _then) = _$PendingInviteCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'trip_id') String tripId, String email, String role, String token,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'expires_at') DateTime? expiresAt
});




}
/// @nodoc
class _$PendingInviteCopyWithImpl<$Res>
    implements $PendingInviteCopyWith<$Res> {
  _$PendingInviteCopyWithImpl(this._self, this._then);

  final PendingInvite _self;
  final $Res Function(PendingInvite) _then;

/// Create a copy of PendingInvite
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? tripId = null,Object? email = null,Object? role = null,Object? token = null,Object? createdAt = freezed,Object? expiresAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [PendingInvite].
extension PendingInvitePatterns on PendingInvite {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PendingInvite value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PendingInvite() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PendingInvite value)  $default,){
final _that = this;
switch (_that) {
case _PendingInvite():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PendingInvite value)?  $default,){
final _that = this;
switch (_that) {
case _PendingInvite() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'trip_id')  String tripId,  String email,  String role,  String token, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'expires_at')  DateTime? expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PendingInvite() when $default != null:
return $default(_that.id,_that.tripId,_that.email,_that.role,_that.token,_that.createdAt,_that.expiresAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'trip_id')  String tripId,  String email,  String role,  String token, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'expires_at')  DateTime? expiresAt)  $default,) {final _that = this;
switch (_that) {
case _PendingInvite():
return $default(_that.id,_that.tripId,_that.email,_that.role,_that.token,_that.createdAt,_that.expiresAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'trip_id')  String tripId,  String email,  String role,  String token, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'expires_at')  DateTime? expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _PendingInvite() when $default != null:
return $default(_that.id,_that.tripId,_that.email,_that.role,_that.token,_that.createdAt,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PendingInvite implements PendingInvite {
  const _PendingInvite({required this.id, @JsonKey(name: 'trip_id') required this.tripId, required this.email, this.role = 'VIEWER', required this.token, @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'expires_at') this.expiresAt});
  factory _PendingInvite.fromJson(Map<String, dynamic> json) => _$PendingInviteFromJson(json);

@override final  String id;
@override@JsonKey(name: 'trip_id') final  String tripId;
@override final  String email;
@override@JsonKey() final  String role;
@override final  String token;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;
@override@JsonKey(name: 'expires_at') final  DateTime? expiresAt;

/// Create a copy of PendingInvite
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PendingInviteCopyWith<_PendingInvite> get copyWith => __$PendingInviteCopyWithImpl<_PendingInvite>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PendingInviteToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PendingInvite&&(identical(other.id, id) || other.id == id)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.email, email) || other.email == email)&&(identical(other.role, role) || other.role == role)&&(identical(other.token, token) || other.token == token)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tripId,email,role,token,createdAt,expiresAt);

@override
String toString() {
  return 'PendingInvite(id: $id, tripId: $tripId, email: $email, role: $role, token: $token, createdAt: $createdAt, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class _$PendingInviteCopyWith<$Res> implements $PendingInviteCopyWith<$Res> {
  factory _$PendingInviteCopyWith(_PendingInvite value, $Res Function(_PendingInvite) _then) = __$PendingInviteCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'trip_id') String tripId, String email, String role, String token,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'expires_at') DateTime? expiresAt
});




}
/// @nodoc
class __$PendingInviteCopyWithImpl<$Res>
    implements _$PendingInviteCopyWith<$Res> {
  __$PendingInviteCopyWithImpl(this._self, this._then);

  final _PendingInvite _self;
  final $Res Function(_PendingInvite) _then;

/// Create a copy of PendingInvite
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tripId = null,Object? email = null,Object? role = null,Object? token = null,Object? createdAt = freezed,Object? expiresAt = freezed,}) {
  return _then(_PendingInvite(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
