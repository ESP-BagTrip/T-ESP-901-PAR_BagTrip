// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trip_cover_candidate.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TripCoverCandidate {

 String get url; String get source; String? get title; String? get attribution;
/// Create a copy of TripCoverCandidate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TripCoverCandidateCopyWith<TripCoverCandidate> get copyWith => _$TripCoverCandidateCopyWithImpl<TripCoverCandidate>(this as TripCoverCandidate, _$identity);

  /// Serializes this TripCoverCandidate to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TripCoverCandidate&&(identical(other.url, url) || other.url == url)&&(identical(other.source, source) || other.source == source)&&(identical(other.title, title) || other.title == title)&&(identical(other.attribution, attribution) || other.attribution == attribution));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,url,source,title,attribution);

@override
String toString() {
  return 'TripCoverCandidate(url: $url, source: $source, title: $title, attribution: $attribution)';
}


}

/// @nodoc
abstract mixin class $TripCoverCandidateCopyWith<$Res>  {
  factory $TripCoverCandidateCopyWith(TripCoverCandidate value, $Res Function(TripCoverCandidate) _then) = _$TripCoverCandidateCopyWithImpl;
@useResult
$Res call({
 String url, String source, String? title, String? attribution
});




}
/// @nodoc
class _$TripCoverCandidateCopyWithImpl<$Res>
    implements $TripCoverCandidateCopyWith<$Res> {
  _$TripCoverCandidateCopyWithImpl(this._self, this._then);

  final TripCoverCandidate _self;
  final $Res Function(TripCoverCandidate) _then;

/// Create a copy of TripCoverCandidate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? url = null,Object? source = null,Object? title = freezed,Object? attribution = freezed,}) {
  return _then(_self.copyWith(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,attribution: freezed == attribution ? _self.attribution : attribution // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TripCoverCandidate].
extension TripCoverCandidatePatterns on TripCoverCandidate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TripCoverCandidate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TripCoverCandidate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TripCoverCandidate value)  $default,){
final _that = this;
switch (_that) {
case _TripCoverCandidate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TripCoverCandidate value)?  $default,){
final _that = this;
switch (_that) {
case _TripCoverCandidate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String url,  String source,  String? title,  String? attribution)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TripCoverCandidate() when $default != null:
return $default(_that.url,_that.source,_that.title,_that.attribution);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String url,  String source,  String? title,  String? attribution)  $default,) {final _that = this;
switch (_that) {
case _TripCoverCandidate():
return $default(_that.url,_that.source,_that.title,_that.attribution);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String url,  String source,  String? title,  String? attribution)?  $default,) {final _that = this;
switch (_that) {
case _TripCoverCandidate() when $default != null:
return $default(_that.url,_that.source,_that.title,_that.attribution);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TripCoverCandidate implements TripCoverCandidate {
  const _TripCoverCandidate({required this.url, required this.source, this.title, this.attribution});
  factory _TripCoverCandidate.fromJson(Map<String, dynamic> json) => _$TripCoverCandidateFromJson(json);

@override final  String url;
@override final  String source;
@override final  String? title;
@override final  String? attribution;

/// Create a copy of TripCoverCandidate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TripCoverCandidateCopyWith<_TripCoverCandidate> get copyWith => __$TripCoverCandidateCopyWithImpl<_TripCoverCandidate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TripCoverCandidateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TripCoverCandidate&&(identical(other.url, url) || other.url == url)&&(identical(other.source, source) || other.source == source)&&(identical(other.title, title) || other.title == title)&&(identical(other.attribution, attribution) || other.attribution == attribution));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,url,source,title,attribution);

@override
String toString() {
  return 'TripCoverCandidate(url: $url, source: $source, title: $title, attribution: $attribution)';
}


}

/// @nodoc
abstract mixin class _$TripCoverCandidateCopyWith<$Res> implements $TripCoverCandidateCopyWith<$Res> {
  factory _$TripCoverCandidateCopyWith(_TripCoverCandidate value, $Res Function(_TripCoverCandidate) _then) = __$TripCoverCandidateCopyWithImpl;
@override @useResult
$Res call({
 String url, String source, String? title, String? attribution
});




}
/// @nodoc
class __$TripCoverCandidateCopyWithImpl<$Res>
    implements _$TripCoverCandidateCopyWith<$Res> {
  __$TripCoverCandidateCopyWithImpl(this._self, this._then);

  final _TripCoverCandidate _self;
  final $Res Function(_TripCoverCandidate) _then;

/// Create a copy of TripCoverCandidate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? url = null,Object? source = null,Object? title = freezed,Object? attribution = freezed,}) {
  return _then(_TripCoverCandidate(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,attribution: freezed == attribution ? _self.attribution : attribution // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
