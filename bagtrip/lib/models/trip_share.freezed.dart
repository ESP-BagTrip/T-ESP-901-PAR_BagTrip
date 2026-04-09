// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trip_share.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TripShare {

 String get id; String get tripId; String? get userId; String get role; DateTime? get invitedAt; String get userEmail; String? get userFullName; String get status;@JsonKey(name: 'invite_token') String? get inviteToken;
/// Create a copy of TripShare
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TripShareCopyWith<TripShare> get copyWith => _$TripShareCopyWithImpl<TripShare>(this as TripShare, _$identity);

  /// Serializes this TripShare to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TripShare&&(identical(other.id, id) || other.id == id)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.role, role) || other.role == role)&&(identical(other.invitedAt, invitedAt) || other.invitedAt == invitedAt)&&(identical(other.userEmail, userEmail) || other.userEmail == userEmail)&&(identical(other.userFullName, userFullName) || other.userFullName == userFullName)&&(identical(other.status, status) || other.status == status)&&(identical(other.inviteToken, inviteToken) || other.inviteToken == inviteToken));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tripId,userId,role,invitedAt,userEmail,userFullName,status,inviteToken);

@override
String toString() {
  return 'TripShare(id: $id, tripId: $tripId, userId: $userId, role: $role, invitedAt: $invitedAt, userEmail: $userEmail, userFullName: $userFullName, status: $status, inviteToken: $inviteToken)';
}


}

/// @nodoc
abstract mixin class $TripShareCopyWith<$Res>  {
  factory $TripShareCopyWith(TripShare value, $Res Function(TripShare) _then) = _$TripShareCopyWithImpl;
@useResult
$Res call({
 String id, String tripId, String? userId, String role, DateTime? invitedAt, String userEmail, String? userFullName, String status,@JsonKey(name: 'invite_token') String? inviteToken
});




}
/// @nodoc
class _$TripShareCopyWithImpl<$Res>
    implements $TripShareCopyWith<$Res> {
  _$TripShareCopyWithImpl(this._self, this._then);

  final TripShare _self;
  final $Res Function(TripShare) _then;

/// Create a copy of TripShare
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? tripId = null,Object? userId = freezed,Object? role = null,Object? invitedAt = freezed,Object? userEmail = null,Object? userFullName = freezed,Object? status = null,Object? inviteToken = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,invitedAt: freezed == invitedAt ? _self.invitedAt : invitedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,userEmail: null == userEmail ? _self.userEmail : userEmail // ignore: cast_nullable_to_non_nullable
as String,userFullName: freezed == userFullName ? _self.userFullName : userFullName // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,inviteToken: freezed == inviteToken ? _self.inviteToken : inviteToken // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TripShare].
extension TripSharePatterns on TripShare {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TripShare value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TripShare() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TripShare value)  $default,){
final _that = this;
switch (_that) {
case _TripShare():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TripShare value)?  $default,){
final _that = this;
switch (_that) {
case _TripShare() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String tripId,  String? userId,  String role,  DateTime? invitedAt,  String userEmail,  String? userFullName,  String status, @JsonKey(name: 'invite_token')  String? inviteToken)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TripShare() when $default != null:
return $default(_that.id,_that.tripId,_that.userId,_that.role,_that.invitedAt,_that.userEmail,_that.userFullName,_that.status,_that.inviteToken);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String tripId,  String? userId,  String role,  DateTime? invitedAt,  String userEmail,  String? userFullName,  String status, @JsonKey(name: 'invite_token')  String? inviteToken)  $default,) {final _that = this;
switch (_that) {
case _TripShare():
return $default(_that.id,_that.tripId,_that.userId,_that.role,_that.invitedAt,_that.userEmail,_that.userFullName,_that.status,_that.inviteToken);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String tripId,  String? userId,  String role,  DateTime? invitedAt,  String userEmail,  String? userFullName,  String status, @JsonKey(name: 'invite_token')  String? inviteToken)?  $default,) {final _that = this;
switch (_that) {
case _TripShare() when $default != null:
return $default(_that.id,_that.tripId,_that.userId,_that.role,_that.invitedAt,_that.userEmail,_that.userFullName,_that.status,_that.inviteToken);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TripShare implements TripShare {
  const _TripShare({required this.id, required this.tripId, this.userId, this.role = 'VIEWER', this.invitedAt, required this.userEmail, this.userFullName, this.status = 'active', @JsonKey(name: 'invite_token') this.inviteToken});
  factory _TripShare.fromJson(Map<String, dynamic> json) => _$TripShareFromJson(json);

@override final  String id;
@override final  String tripId;
@override final  String? userId;
@override@JsonKey() final  String role;
@override final  DateTime? invitedAt;
@override final  String userEmail;
@override final  String? userFullName;
@override@JsonKey() final  String status;
@override@JsonKey(name: 'invite_token') final  String? inviteToken;

/// Create a copy of TripShare
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TripShareCopyWith<_TripShare> get copyWith => __$TripShareCopyWithImpl<_TripShare>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TripShareToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TripShare&&(identical(other.id, id) || other.id == id)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.role, role) || other.role == role)&&(identical(other.invitedAt, invitedAt) || other.invitedAt == invitedAt)&&(identical(other.userEmail, userEmail) || other.userEmail == userEmail)&&(identical(other.userFullName, userFullName) || other.userFullName == userFullName)&&(identical(other.status, status) || other.status == status)&&(identical(other.inviteToken, inviteToken) || other.inviteToken == inviteToken));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tripId,userId,role,invitedAt,userEmail,userFullName,status,inviteToken);

@override
String toString() {
  return 'TripShare(id: $id, tripId: $tripId, userId: $userId, role: $role, invitedAt: $invitedAt, userEmail: $userEmail, userFullName: $userFullName, status: $status, inviteToken: $inviteToken)';
}


}

/// @nodoc
abstract mixin class _$TripShareCopyWith<$Res> implements $TripShareCopyWith<$Res> {
  factory _$TripShareCopyWith(_TripShare value, $Res Function(_TripShare) _then) = __$TripShareCopyWithImpl;
@override @useResult
$Res call({
 String id, String tripId, String? userId, String role, DateTime? invitedAt, String userEmail, String? userFullName, String status,@JsonKey(name: 'invite_token') String? inviteToken
});




}
/// @nodoc
class __$TripShareCopyWithImpl<$Res>
    implements _$TripShareCopyWith<$Res> {
  __$TripShareCopyWithImpl(this._self, this._then);

  final _TripShare _self;
  final $Res Function(_TripShare) _then;

/// Create a copy of TripShare
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tripId = null,Object? userId = freezed,Object? role = null,Object? invitedAt = freezed,Object? userEmail = null,Object? userFullName = freezed,Object? status = null,Object? inviteToken = freezed,}) {
  return _then(_TripShare(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,invitedAt: freezed == invitedAt ? _self.invitedAt : invitedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,userEmail: null == userEmail ? _self.userEmail : userEmail // ignore: cast_nullable_to_non_nullable
as String,userFullName: freezed == userFullName ? _self.userFullName : userFullName // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,inviteToken: freezed == inviteToken ? _self.inviteToken : inviteToken // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
