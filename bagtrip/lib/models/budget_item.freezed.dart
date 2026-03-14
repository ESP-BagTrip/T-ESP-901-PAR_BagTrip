// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'budget_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BudgetItem {

 String get id; String get tripId; String get label; double get amount; BudgetCategory get category; DateTime? get date; bool get isPlanned; DateTime? get createdAt; DateTime? get updatedAt;
/// Create a copy of BudgetItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BudgetItemCopyWith<BudgetItem> get copyWith => _$BudgetItemCopyWithImpl<BudgetItem>(this as BudgetItem, _$identity);

  /// Serializes this BudgetItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BudgetItem&&(identical(other.id, id) || other.id == id)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.label, label) || other.label == label)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.category, category) || other.category == category)&&(identical(other.date, date) || other.date == date)&&(identical(other.isPlanned, isPlanned) || other.isPlanned == isPlanned)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tripId,label,amount,category,date,isPlanned,createdAt,updatedAt);

@override
String toString() {
  return 'BudgetItem(id: $id, tripId: $tripId, label: $label, amount: $amount, category: $category, date: $date, isPlanned: $isPlanned, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $BudgetItemCopyWith<$Res>  {
  factory $BudgetItemCopyWith(BudgetItem value, $Res Function(BudgetItem) _then) = _$BudgetItemCopyWithImpl;
@useResult
$Res call({
 String id, String tripId, String label, double amount, BudgetCategory category, DateTime? date, bool isPlanned, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class _$BudgetItemCopyWithImpl<$Res>
    implements $BudgetItemCopyWith<$Res> {
  _$BudgetItemCopyWithImpl(this._self, this._then);

  final BudgetItem _self;
  final $Res Function(BudgetItem) _then;

/// Create a copy of BudgetItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? tripId = null,Object? label = null,Object? amount = null,Object? category = null,Object? date = freezed,Object? isPlanned = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as BudgetCategory,date: freezed == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime?,isPlanned: null == isPlanned ? _self.isPlanned : isPlanned // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [BudgetItem].
extension BudgetItemPatterns on BudgetItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BudgetItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BudgetItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BudgetItem value)  $default,){
final _that = this;
switch (_that) {
case _BudgetItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BudgetItem value)?  $default,){
final _that = this;
switch (_that) {
case _BudgetItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String tripId,  String label,  double amount,  BudgetCategory category,  DateTime? date,  bool isPlanned,  DateTime? createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BudgetItem() when $default != null:
return $default(_that.id,_that.tripId,_that.label,_that.amount,_that.category,_that.date,_that.isPlanned,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String tripId,  String label,  double amount,  BudgetCategory category,  DateTime? date,  bool isPlanned,  DateTime? createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _BudgetItem():
return $default(_that.id,_that.tripId,_that.label,_that.amount,_that.category,_that.date,_that.isPlanned,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String tripId,  String label,  double amount,  BudgetCategory category,  DateTime? date,  bool isPlanned,  DateTime? createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _BudgetItem() when $default != null:
return $default(_that.id,_that.tripId,_that.label,_that.amount,_that.category,_that.date,_that.isPlanned,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BudgetItem implements BudgetItem {
  const _BudgetItem({required this.id, required this.tripId, required this.label, required this.amount, this.category = BudgetCategory.other, this.date, this.isPlanned = true, this.createdAt, this.updatedAt});
  factory _BudgetItem.fromJson(Map<String, dynamic> json) => _$BudgetItemFromJson(json);

@override final  String id;
@override final  String tripId;
@override final  String label;
@override final  double amount;
@override@JsonKey() final  BudgetCategory category;
@override final  DateTime? date;
@override@JsonKey() final  bool isPlanned;
@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;

/// Create a copy of BudgetItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BudgetItemCopyWith<_BudgetItem> get copyWith => __$BudgetItemCopyWithImpl<_BudgetItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BudgetItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BudgetItem&&(identical(other.id, id) || other.id == id)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.label, label) || other.label == label)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.category, category) || other.category == category)&&(identical(other.date, date) || other.date == date)&&(identical(other.isPlanned, isPlanned) || other.isPlanned == isPlanned)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tripId,label,amount,category,date,isPlanned,createdAt,updatedAt);

@override
String toString() {
  return 'BudgetItem(id: $id, tripId: $tripId, label: $label, amount: $amount, category: $category, date: $date, isPlanned: $isPlanned, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$BudgetItemCopyWith<$Res> implements $BudgetItemCopyWith<$Res> {
  factory _$BudgetItemCopyWith(_BudgetItem value, $Res Function(_BudgetItem) _then) = __$BudgetItemCopyWithImpl;
@override @useResult
$Res call({
 String id, String tripId, String label, double amount, BudgetCategory category, DateTime? date, bool isPlanned, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class __$BudgetItemCopyWithImpl<$Res>
    implements _$BudgetItemCopyWith<$Res> {
  __$BudgetItemCopyWithImpl(this._self, this._then);

  final _BudgetItem _self;
  final $Res Function(_BudgetItem) _then;

/// Create a copy of BudgetItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tripId = null,Object? label = null,Object? amount = null,Object? category = null,Object? date = freezed,Object? isPlanned = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_BudgetItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as BudgetCategory,date: freezed == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime?,isPlanned: null == isPlanned ? _self.isPlanned : isPlanned // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$BudgetSummary {

 double get totalBudget; double get totalSpent; double get remaining; Map<String, double> get byCategory; double? get percentConsumed; String? get alertLevel; String? get alertMessage;
/// Create a copy of BudgetSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BudgetSummaryCopyWith<BudgetSummary> get copyWith => _$BudgetSummaryCopyWithImpl<BudgetSummary>(this as BudgetSummary, _$identity);

  /// Serializes this BudgetSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BudgetSummary&&(identical(other.totalBudget, totalBudget) || other.totalBudget == totalBudget)&&(identical(other.totalSpent, totalSpent) || other.totalSpent == totalSpent)&&(identical(other.remaining, remaining) || other.remaining == remaining)&&const DeepCollectionEquality().equals(other.byCategory, byCategory)&&(identical(other.percentConsumed, percentConsumed) || other.percentConsumed == percentConsumed)&&(identical(other.alertLevel, alertLevel) || other.alertLevel == alertLevel)&&(identical(other.alertMessage, alertMessage) || other.alertMessage == alertMessage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,totalBudget,totalSpent,remaining,const DeepCollectionEquality().hash(byCategory),percentConsumed,alertLevel,alertMessage);

@override
String toString() {
  return 'BudgetSummary(totalBudget: $totalBudget, totalSpent: $totalSpent, remaining: $remaining, byCategory: $byCategory, percentConsumed: $percentConsumed, alertLevel: $alertLevel, alertMessage: $alertMessage)';
}


}

/// @nodoc
abstract mixin class $BudgetSummaryCopyWith<$Res>  {
  factory $BudgetSummaryCopyWith(BudgetSummary value, $Res Function(BudgetSummary) _then) = _$BudgetSummaryCopyWithImpl;
@useResult
$Res call({
 double totalBudget, double totalSpent, double remaining, Map<String, double> byCategory, double? percentConsumed, String? alertLevel, String? alertMessage
});




}
/// @nodoc
class _$BudgetSummaryCopyWithImpl<$Res>
    implements $BudgetSummaryCopyWith<$Res> {
  _$BudgetSummaryCopyWithImpl(this._self, this._then);

  final BudgetSummary _self;
  final $Res Function(BudgetSummary) _then;

/// Create a copy of BudgetSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? totalBudget = null,Object? totalSpent = null,Object? remaining = null,Object? byCategory = null,Object? percentConsumed = freezed,Object? alertLevel = freezed,Object? alertMessage = freezed,}) {
  return _then(_self.copyWith(
totalBudget: null == totalBudget ? _self.totalBudget : totalBudget // ignore: cast_nullable_to_non_nullable
as double,totalSpent: null == totalSpent ? _self.totalSpent : totalSpent // ignore: cast_nullable_to_non_nullable
as double,remaining: null == remaining ? _self.remaining : remaining // ignore: cast_nullable_to_non_nullable
as double,byCategory: null == byCategory ? _self.byCategory : byCategory // ignore: cast_nullable_to_non_nullable
as Map<String, double>,percentConsumed: freezed == percentConsumed ? _self.percentConsumed : percentConsumed // ignore: cast_nullable_to_non_nullable
as double?,alertLevel: freezed == alertLevel ? _self.alertLevel : alertLevel // ignore: cast_nullable_to_non_nullable
as String?,alertMessage: freezed == alertMessage ? _self.alertMessage : alertMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [BudgetSummary].
extension BudgetSummaryPatterns on BudgetSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BudgetSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BudgetSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BudgetSummary value)  $default,){
final _that = this;
switch (_that) {
case _BudgetSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BudgetSummary value)?  $default,){
final _that = this;
switch (_that) {
case _BudgetSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double totalBudget,  double totalSpent,  double remaining,  Map<String, double> byCategory,  double? percentConsumed,  String? alertLevel,  String? alertMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BudgetSummary() when $default != null:
return $default(_that.totalBudget,_that.totalSpent,_that.remaining,_that.byCategory,_that.percentConsumed,_that.alertLevel,_that.alertMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double totalBudget,  double totalSpent,  double remaining,  Map<String, double> byCategory,  double? percentConsumed,  String? alertLevel,  String? alertMessage)  $default,) {final _that = this;
switch (_that) {
case _BudgetSummary():
return $default(_that.totalBudget,_that.totalSpent,_that.remaining,_that.byCategory,_that.percentConsumed,_that.alertLevel,_that.alertMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double totalBudget,  double totalSpent,  double remaining,  Map<String, double> byCategory,  double? percentConsumed,  String? alertLevel,  String? alertMessage)?  $default,) {final _that = this;
switch (_that) {
case _BudgetSummary() when $default != null:
return $default(_that.totalBudget,_that.totalSpent,_that.remaining,_that.byCategory,_that.percentConsumed,_that.alertLevel,_that.alertMessage);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BudgetSummary implements BudgetSummary {
  const _BudgetSummary({this.totalBudget = 0, this.totalSpent = 0, this.remaining = 0, final  Map<String, double> byCategory = const {}, this.percentConsumed, this.alertLevel, this.alertMessage}): _byCategory = byCategory;
  factory _BudgetSummary.fromJson(Map<String, dynamic> json) => _$BudgetSummaryFromJson(json);

@override@JsonKey() final  double totalBudget;
@override@JsonKey() final  double totalSpent;
@override@JsonKey() final  double remaining;
 final  Map<String, double> _byCategory;
@override@JsonKey() Map<String, double> get byCategory {
  if (_byCategory is EqualUnmodifiableMapView) return _byCategory;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_byCategory);
}

@override final  double? percentConsumed;
@override final  String? alertLevel;
@override final  String? alertMessage;

/// Create a copy of BudgetSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BudgetSummaryCopyWith<_BudgetSummary> get copyWith => __$BudgetSummaryCopyWithImpl<_BudgetSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BudgetSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BudgetSummary&&(identical(other.totalBudget, totalBudget) || other.totalBudget == totalBudget)&&(identical(other.totalSpent, totalSpent) || other.totalSpent == totalSpent)&&(identical(other.remaining, remaining) || other.remaining == remaining)&&const DeepCollectionEquality().equals(other._byCategory, _byCategory)&&(identical(other.percentConsumed, percentConsumed) || other.percentConsumed == percentConsumed)&&(identical(other.alertLevel, alertLevel) || other.alertLevel == alertLevel)&&(identical(other.alertMessage, alertMessage) || other.alertMessage == alertMessage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,totalBudget,totalSpent,remaining,const DeepCollectionEquality().hash(_byCategory),percentConsumed,alertLevel,alertMessage);

@override
String toString() {
  return 'BudgetSummary(totalBudget: $totalBudget, totalSpent: $totalSpent, remaining: $remaining, byCategory: $byCategory, percentConsumed: $percentConsumed, alertLevel: $alertLevel, alertMessage: $alertMessage)';
}


}

/// @nodoc
abstract mixin class _$BudgetSummaryCopyWith<$Res> implements $BudgetSummaryCopyWith<$Res> {
  factory _$BudgetSummaryCopyWith(_BudgetSummary value, $Res Function(_BudgetSummary) _then) = __$BudgetSummaryCopyWithImpl;
@override @useResult
$Res call({
 double totalBudget, double totalSpent, double remaining, Map<String, double> byCategory, double? percentConsumed, String? alertLevel, String? alertMessage
});




}
/// @nodoc
class __$BudgetSummaryCopyWithImpl<$Res>
    implements _$BudgetSummaryCopyWith<$Res> {
  __$BudgetSummaryCopyWithImpl(this._self, this._then);

  final _BudgetSummary _self;
  final $Res Function(_BudgetSummary) _then;

/// Create a copy of BudgetSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? totalBudget = null,Object? totalSpent = null,Object? remaining = null,Object? byCategory = null,Object? percentConsumed = freezed,Object? alertLevel = freezed,Object? alertMessage = freezed,}) {
  return _then(_BudgetSummary(
totalBudget: null == totalBudget ? _self.totalBudget : totalBudget // ignore: cast_nullable_to_non_nullable
as double,totalSpent: null == totalSpent ? _self.totalSpent : totalSpent // ignore: cast_nullable_to_non_nullable
as double,remaining: null == remaining ? _self.remaining : remaining // ignore: cast_nullable_to_non_nullable
as double,byCategory: null == byCategory ? _self._byCategory : byCategory // ignore: cast_nullable_to_non_nullable
as Map<String, double>,percentConsumed: freezed == percentConsumed ? _self.percentConsumed : percentConsumed // ignore: cast_nullable_to_non_nullable
as double?,alertLevel: freezed == alertLevel ? _self.alertLevel : alertLevel // ignore: cast_nullable_to_non_nullable
as String?,alertMessage: freezed == alertMessage ? _self.alertMessage : alertMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
