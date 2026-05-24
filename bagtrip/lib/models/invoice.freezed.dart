// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'invoice.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Invoice {

 String get id; String? get number; String? get status;@JsonKey(name: 'amount_paid') int? get amountPaid; String? get currency; DateTime? get created;@JsonKey(name: 'hosted_invoice_url') String? get hostedInvoiceUrl;@JsonKey(name: 'invoice_pdf') String? get invoicePdf;
/// Create a copy of Invoice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvoiceCopyWith<Invoice> get copyWith => _$InvoiceCopyWithImpl<Invoice>(this as Invoice, _$identity);

  /// Serializes this Invoice to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Invoice&&(identical(other.id, id) || other.id == id)&&(identical(other.number, number) || other.number == number)&&(identical(other.status, status) || other.status == status)&&(identical(other.amountPaid, amountPaid) || other.amountPaid == amountPaid)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.created, created) || other.created == created)&&(identical(other.hostedInvoiceUrl, hostedInvoiceUrl) || other.hostedInvoiceUrl == hostedInvoiceUrl)&&(identical(other.invoicePdf, invoicePdf) || other.invoicePdf == invoicePdf));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,number,status,amountPaid,currency,created,hostedInvoiceUrl,invoicePdf);

@override
String toString() {
  return 'Invoice(id: $id, number: $number, status: $status, amountPaid: $amountPaid, currency: $currency, created: $created, hostedInvoiceUrl: $hostedInvoiceUrl, invoicePdf: $invoicePdf)';
}


}

/// @nodoc
abstract mixin class $InvoiceCopyWith<$Res>  {
  factory $InvoiceCopyWith(Invoice value, $Res Function(Invoice) _then) = _$InvoiceCopyWithImpl;
@useResult
$Res call({
 String id, String? number, String? status,@JsonKey(name: 'amount_paid') int? amountPaid, String? currency, DateTime? created,@JsonKey(name: 'hosted_invoice_url') String? hostedInvoiceUrl,@JsonKey(name: 'invoice_pdf') String? invoicePdf
});




}
/// @nodoc
class _$InvoiceCopyWithImpl<$Res>
    implements $InvoiceCopyWith<$Res> {
  _$InvoiceCopyWithImpl(this._self, this._then);

  final Invoice _self;
  final $Res Function(Invoice) _then;

/// Create a copy of Invoice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? number = freezed,Object? status = freezed,Object? amountPaid = freezed,Object? currency = freezed,Object? created = freezed,Object? hostedInvoiceUrl = freezed,Object? invoicePdf = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,number: freezed == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,amountPaid: freezed == amountPaid ? _self.amountPaid : amountPaid // ignore: cast_nullable_to_non_nullable
as int?,currency: freezed == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String?,created: freezed == created ? _self.created : created // ignore: cast_nullable_to_non_nullable
as DateTime?,hostedInvoiceUrl: freezed == hostedInvoiceUrl ? _self.hostedInvoiceUrl : hostedInvoiceUrl // ignore: cast_nullable_to_non_nullable
as String?,invoicePdf: freezed == invoicePdf ? _self.invoicePdf : invoicePdf // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Invoice].
extension InvoicePatterns on Invoice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Invoice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Invoice() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Invoice value)  $default,){
final _that = this;
switch (_that) {
case _Invoice():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Invoice value)?  $default,){
final _that = this;
switch (_that) {
case _Invoice() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? number,  String? status, @JsonKey(name: 'amount_paid')  int? amountPaid,  String? currency,  DateTime? created, @JsonKey(name: 'hosted_invoice_url')  String? hostedInvoiceUrl, @JsonKey(name: 'invoice_pdf')  String? invoicePdf)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Invoice() when $default != null:
return $default(_that.id,_that.number,_that.status,_that.amountPaid,_that.currency,_that.created,_that.hostedInvoiceUrl,_that.invoicePdf);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? number,  String? status, @JsonKey(name: 'amount_paid')  int? amountPaid,  String? currency,  DateTime? created, @JsonKey(name: 'hosted_invoice_url')  String? hostedInvoiceUrl, @JsonKey(name: 'invoice_pdf')  String? invoicePdf)  $default,) {final _that = this;
switch (_that) {
case _Invoice():
return $default(_that.id,_that.number,_that.status,_that.amountPaid,_that.currency,_that.created,_that.hostedInvoiceUrl,_that.invoicePdf);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? number,  String? status, @JsonKey(name: 'amount_paid')  int? amountPaid,  String? currency,  DateTime? created, @JsonKey(name: 'hosted_invoice_url')  String? hostedInvoiceUrl, @JsonKey(name: 'invoice_pdf')  String? invoicePdf)?  $default,) {final _that = this;
switch (_that) {
case _Invoice() when $default != null:
return $default(_that.id,_that.number,_that.status,_that.amountPaid,_that.currency,_that.created,_that.hostedInvoiceUrl,_that.invoicePdf);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Invoice extends Invoice {
  const _Invoice({required this.id, this.number, this.status, @JsonKey(name: 'amount_paid') this.amountPaid, this.currency, this.created, @JsonKey(name: 'hosted_invoice_url') this.hostedInvoiceUrl, @JsonKey(name: 'invoice_pdf') this.invoicePdf}): super._();
  factory _Invoice.fromJson(Map<String, dynamic> json) => _$InvoiceFromJson(json);

@override final  String id;
@override final  String? number;
@override final  String? status;
@override@JsonKey(name: 'amount_paid') final  int? amountPaid;
@override final  String? currency;
@override final  DateTime? created;
@override@JsonKey(name: 'hosted_invoice_url') final  String? hostedInvoiceUrl;
@override@JsonKey(name: 'invoice_pdf') final  String? invoicePdf;

/// Create a copy of Invoice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InvoiceCopyWith<_Invoice> get copyWith => __$InvoiceCopyWithImpl<_Invoice>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InvoiceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Invoice&&(identical(other.id, id) || other.id == id)&&(identical(other.number, number) || other.number == number)&&(identical(other.status, status) || other.status == status)&&(identical(other.amountPaid, amountPaid) || other.amountPaid == amountPaid)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.created, created) || other.created == created)&&(identical(other.hostedInvoiceUrl, hostedInvoiceUrl) || other.hostedInvoiceUrl == hostedInvoiceUrl)&&(identical(other.invoicePdf, invoicePdf) || other.invoicePdf == invoicePdf));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,number,status,amountPaid,currency,created,hostedInvoiceUrl,invoicePdf);

@override
String toString() {
  return 'Invoice(id: $id, number: $number, status: $status, amountPaid: $amountPaid, currency: $currency, created: $created, hostedInvoiceUrl: $hostedInvoiceUrl, invoicePdf: $invoicePdf)';
}


}

/// @nodoc
abstract mixin class _$InvoiceCopyWith<$Res> implements $InvoiceCopyWith<$Res> {
  factory _$InvoiceCopyWith(_Invoice value, $Res Function(_Invoice) _then) = __$InvoiceCopyWithImpl;
@override @useResult
$Res call({
 String id, String? number, String? status,@JsonKey(name: 'amount_paid') int? amountPaid, String? currency, DateTime? created,@JsonKey(name: 'hosted_invoice_url') String? hostedInvoiceUrl,@JsonKey(name: 'invoice_pdf') String? invoicePdf
});




}
/// @nodoc
class __$InvoiceCopyWithImpl<$Res>
    implements _$InvoiceCopyWith<$Res> {
  __$InvoiceCopyWithImpl(this._self, this._then);

  final _Invoice _self;
  final $Res Function(_Invoice) _then;

/// Create a copy of Invoice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? number = freezed,Object? status = freezed,Object? amountPaid = freezed,Object? currency = freezed,Object? created = freezed,Object? hostedInvoiceUrl = freezed,Object? invoicePdf = freezed,}) {
  return _then(_Invoice(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,number: freezed == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,amountPaid: freezed == amountPaid ? _self.amountPaid : amountPaid // ignore: cast_nullable_to_non_nullable
as int?,currency: freezed == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String?,created: freezed == created ? _self.created : created // ignore: cast_nullable_to_non_nullable
as DateTime?,hostedInvoiceUrl: freezed == hostedInvoiceUrl ? _self.hostedInvoiceUrl : hostedInvoiceUrl // ignore: cast_nullable_to_non_nullable
as String?,invoicePdf: freezed == invoicePdf ? _self.invoicePdf : invoicePdf // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
