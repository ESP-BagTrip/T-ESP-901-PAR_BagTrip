// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'plan_trip_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PlanTripEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlanTripEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PlanTripEvent()';
}


}

/// @nodoc
class $PlanTripEventCopyWith<$Res>  {
$PlanTripEventCopyWith(PlanTripEvent _, $Res Function(PlanTripEvent) __);
}


/// Adds pattern-matching-related methods to [PlanTripEvent].
extension PlanTripEventPatterns on PlanTripEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PlanTripLoadPersonalization value)?  loadPersonalization,TResult Function( PlanTripNextStep value)?  nextStep,TResult Function( PlanTripPreviousStep value)?  previousStep,TResult Function( PlanTripGoToStep value)?  goToStep,TResult Function( PlanTripSetDateMode value)?  setDateMode,TResult Function( PlanTripSetExactDates value)?  setExactDates,TResult Function( PlanTripSetMonthPreference value)?  setMonthPreference,TResult Function( PlanTripSetFlexibleDuration value)?  setFlexibleDuration,TResult Function( PlanTripSetTravelerCounts value)?  setTravelerCounts,TResult Function( PlanTripSetBudgetPreset value)?  setBudgetPreset,TResult Function( PlanTripSetOriginCity value)?  setOriginCity,TResult Function( PlanTripSearchOrigin value)?  searchOrigin,TResult Function( PlanTripSearchDestination value)?  searchDestination,TResult Function( PlanTripSelectManualDestination value)?  selectManualDestination,TResult Function( PlanTripRequestAiSuggestions value)?  requestAiSuggestions,TResult Function( PlanTripSelectAiDestination value)?  selectAiDestination,TResult Function( PlanTripSwipeProposal value)?  swipeProposal,TResult Function( PlanTripStartGeneration value)?  startGeneration,TResult Function( PlanTripRetryGeneration value)?  retryGeneration,TResult Function( PlanTripCreateTrip value)?  createTrip,TResult Function( PlanTripBackToProposals value)?  backToProposals,TResult Function( PlanTripUpdateReviewDates value)?  updateReviewDates,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PlanTripLoadPersonalization() when loadPersonalization != null:
return loadPersonalization(_that);case PlanTripNextStep() when nextStep != null:
return nextStep(_that);case PlanTripPreviousStep() when previousStep != null:
return previousStep(_that);case PlanTripGoToStep() when goToStep != null:
return goToStep(_that);case PlanTripSetDateMode() when setDateMode != null:
return setDateMode(_that);case PlanTripSetExactDates() when setExactDates != null:
return setExactDates(_that);case PlanTripSetMonthPreference() when setMonthPreference != null:
return setMonthPreference(_that);case PlanTripSetFlexibleDuration() when setFlexibleDuration != null:
return setFlexibleDuration(_that);case PlanTripSetTravelerCounts() when setTravelerCounts != null:
return setTravelerCounts(_that);case PlanTripSetBudgetPreset() when setBudgetPreset != null:
return setBudgetPreset(_that);case PlanTripSetOriginCity() when setOriginCity != null:
return setOriginCity(_that);case PlanTripSearchOrigin() when searchOrigin != null:
return searchOrigin(_that);case PlanTripSearchDestination() when searchDestination != null:
return searchDestination(_that);case PlanTripSelectManualDestination() when selectManualDestination != null:
return selectManualDestination(_that);case PlanTripRequestAiSuggestions() when requestAiSuggestions != null:
return requestAiSuggestions(_that);case PlanTripSelectAiDestination() when selectAiDestination != null:
return selectAiDestination(_that);case PlanTripSwipeProposal() when swipeProposal != null:
return swipeProposal(_that);case PlanTripStartGeneration() when startGeneration != null:
return startGeneration(_that);case PlanTripRetryGeneration() when retryGeneration != null:
return retryGeneration(_that);case PlanTripCreateTrip() when createTrip != null:
return createTrip(_that);case PlanTripBackToProposals() when backToProposals != null:
return backToProposals(_that);case PlanTripUpdateReviewDates() when updateReviewDates != null:
return updateReviewDates(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PlanTripLoadPersonalization value)  loadPersonalization,required TResult Function( PlanTripNextStep value)  nextStep,required TResult Function( PlanTripPreviousStep value)  previousStep,required TResult Function( PlanTripGoToStep value)  goToStep,required TResult Function( PlanTripSetDateMode value)  setDateMode,required TResult Function( PlanTripSetExactDates value)  setExactDates,required TResult Function( PlanTripSetMonthPreference value)  setMonthPreference,required TResult Function( PlanTripSetFlexibleDuration value)  setFlexibleDuration,required TResult Function( PlanTripSetTravelerCounts value)  setTravelerCounts,required TResult Function( PlanTripSetBudgetPreset value)  setBudgetPreset,required TResult Function( PlanTripSetOriginCity value)  setOriginCity,required TResult Function( PlanTripSearchOrigin value)  searchOrigin,required TResult Function( PlanTripSearchDestination value)  searchDestination,required TResult Function( PlanTripSelectManualDestination value)  selectManualDestination,required TResult Function( PlanTripRequestAiSuggestions value)  requestAiSuggestions,required TResult Function( PlanTripSelectAiDestination value)  selectAiDestination,required TResult Function( PlanTripSwipeProposal value)  swipeProposal,required TResult Function( PlanTripStartGeneration value)  startGeneration,required TResult Function( PlanTripRetryGeneration value)  retryGeneration,required TResult Function( PlanTripCreateTrip value)  createTrip,required TResult Function( PlanTripBackToProposals value)  backToProposals,required TResult Function( PlanTripUpdateReviewDates value)  updateReviewDates,}){
final _that = this;
switch (_that) {
case PlanTripLoadPersonalization():
return loadPersonalization(_that);case PlanTripNextStep():
return nextStep(_that);case PlanTripPreviousStep():
return previousStep(_that);case PlanTripGoToStep():
return goToStep(_that);case PlanTripSetDateMode():
return setDateMode(_that);case PlanTripSetExactDates():
return setExactDates(_that);case PlanTripSetMonthPreference():
return setMonthPreference(_that);case PlanTripSetFlexibleDuration():
return setFlexibleDuration(_that);case PlanTripSetTravelerCounts():
return setTravelerCounts(_that);case PlanTripSetBudgetPreset():
return setBudgetPreset(_that);case PlanTripSetOriginCity():
return setOriginCity(_that);case PlanTripSearchOrigin():
return searchOrigin(_that);case PlanTripSearchDestination():
return searchDestination(_that);case PlanTripSelectManualDestination():
return selectManualDestination(_that);case PlanTripRequestAiSuggestions():
return requestAiSuggestions(_that);case PlanTripSelectAiDestination():
return selectAiDestination(_that);case PlanTripSwipeProposal():
return swipeProposal(_that);case PlanTripStartGeneration():
return startGeneration(_that);case PlanTripRetryGeneration():
return retryGeneration(_that);case PlanTripCreateTrip():
return createTrip(_that);case PlanTripBackToProposals():
return backToProposals(_that);case PlanTripUpdateReviewDates():
return updateReviewDates(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PlanTripLoadPersonalization value)?  loadPersonalization,TResult? Function( PlanTripNextStep value)?  nextStep,TResult? Function( PlanTripPreviousStep value)?  previousStep,TResult? Function( PlanTripGoToStep value)?  goToStep,TResult? Function( PlanTripSetDateMode value)?  setDateMode,TResult? Function( PlanTripSetExactDates value)?  setExactDates,TResult? Function( PlanTripSetMonthPreference value)?  setMonthPreference,TResult? Function( PlanTripSetFlexibleDuration value)?  setFlexibleDuration,TResult? Function( PlanTripSetTravelerCounts value)?  setTravelerCounts,TResult? Function( PlanTripSetBudgetPreset value)?  setBudgetPreset,TResult? Function( PlanTripSetOriginCity value)?  setOriginCity,TResult? Function( PlanTripSearchOrigin value)?  searchOrigin,TResult? Function( PlanTripSearchDestination value)?  searchDestination,TResult? Function( PlanTripSelectManualDestination value)?  selectManualDestination,TResult? Function( PlanTripRequestAiSuggestions value)?  requestAiSuggestions,TResult? Function( PlanTripSelectAiDestination value)?  selectAiDestination,TResult? Function( PlanTripSwipeProposal value)?  swipeProposal,TResult? Function( PlanTripStartGeneration value)?  startGeneration,TResult? Function( PlanTripRetryGeneration value)?  retryGeneration,TResult? Function( PlanTripCreateTrip value)?  createTrip,TResult? Function( PlanTripBackToProposals value)?  backToProposals,TResult? Function( PlanTripUpdateReviewDates value)?  updateReviewDates,}){
final _that = this;
switch (_that) {
case PlanTripLoadPersonalization() when loadPersonalization != null:
return loadPersonalization(_that);case PlanTripNextStep() when nextStep != null:
return nextStep(_that);case PlanTripPreviousStep() when previousStep != null:
return previousStep(_that);case PlanTripGoToStep() when goToStep != null:
return goToStep(_that);case PlanTripSetDateMode() when setDateMode != null:
return setDateMode(_that);case PlanTripSetExactDates() when setExactDates != null:
return setExactDates(_that);case PlanTripSetMonthPreference() when setMonthPreference != null:
return setMonthPreference(_that);case PlanTripSetFlexibleDuration() when setFlexibleDuration != null:
return setFlexibleDuration(_that);case PlanTripSetTravelerCounts() when setTravelerCounts != null:
return setTravelerCounts(_that);case PlanTripSetBudgetPreset() when setBudgetPreset != null:
return setBudgetPreset(_that);case PlanTripSetOriginCity() when setOriginCity != null:
return setOriginCity(_that);case PlanTripSearchOrigin() when searchOrigin != null:
return searchOrigin(_that);case PlanTripSearchDestination() when searchDestination != null:
return searchDestination(_that);case PlanTripSelectManualDestination() when selectManualDestination != null:
return selectManualDestination(_that);case PlanTripRequestAiSuggestions() when requestAiSuggestions != null:
return requestAiSuggestions(_that);case PlanTripSelectAiDestination() when selectAiDestination != null:
return selectAiDestination(_that);case PlanTripSwipeProposal() when swipeProposal != null:
return swipeProposal(_that);case PlanTripStartGeneration() when startGeneration != null:
return startGeneration(_that);case PlanTripRetryGeneration() when retryGeneration != null:
return retryGeneration(_that);case PlanTripCreateTrip() when createTrip != null:
return createTrip(_that);case PlanTripBackToProposals() when backToProposals != null:
return backToProposals(_that);case PlanTripUpdateReviewDates() when updateReviewDates != null:
return updateReviewDates(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loadPersonalization,TResult Function()?  nextStep,TResult Function()?  previousStep,TResult Function( int step)?  goToStep,TResult Function( DateMode mode)?  setDateMode,TResult Function( DateTime start,  DateTime end)?  setExactDates,TResult Function( int month,  int year)?  setMonthPreference,TResult Function( DurationPreset preset)?  setFlexibleDuration,TResult Function( int? adults,  int? children,  int? babies)?  setTravelerCounts,TResult Function( BudgetPreset? preset)?  setBudgetPreset,TResult Function( String city)?  setOriginCity,TResult Function( String query)?  searchOrigin,TResult Function( String query)?  searchDestination,TResult Function( LocationResult location)?  selectManualDestination,TResult Function()?  requestAiSuggestions,TResult Function( AiDestination destination)?  selectAiDestination,TResult Function( int index)?  swipeProposal,TResult Function()?  startGeneration,TResult Function()?  retryGeneration,TResult Function()?  createTrip,TResult Function()?  backToProposals,TResult Function( DateTime start,  DateTime end)?  updateReviewDates,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PlanTripLoadPersonalization() when loadPersonalization != null:
return loadPersonalization();case PlanTripNextStep() when nextStep != null:
return nextStep();case PlanTripPreviousStep() when previousStep != null:
return previousStep();case PlanTripGoToStep() when goToStep != null:
return goToStep(_that.step);case PlanTripSetDateMode() when setDateMode != null:
return setDateMode(_that.mode);case PlanTripSetExactDates() when setExactDates != null:
return setExactDates(_that.start,_that.end);case PlanTripSetMonthPreference() when setMonthPreference != null:
return setMonthPreference(_that.month,_that.year);case PlanTripSetFlexibleDuration() when setFlexibleDuration != null:
return setFlexibleDuration(_that.preset);case PlanTripSetTravelerCounts() when setTravelerCounts != null:
return setTravelerCounts(_that.adults,_that.children,_that.babies);case PlanTripSetBudgetPreset() when setBudgetPreset != null:
return setBudgetPreset(_that.preset);case PlanTripSetOriginCity() when setOriginCity != null:
return setOriginCity(_that.city);case PlanTripSearchOrigin() when searchOrigin != null:
return searchOrigin(_that.query);case PlanTripSearchDestination() when searchDestination != null:
return searchDestination(_that.query);case PlanTripSelectManualDestination() when selectManualDestination != null:
return selectManualDestination(_that.location);case PlanTripRequestAiSuggestions() when requestAiSuggestions != null:
return requestAiSuggestions();case PlanTripSelectAiDestination() when selectAiDestination != null:
return selectAiDestination(_that.destination);case PlanTripSwipeProposal() when swipeProposal != null:
return swipeProposal(_that.index);case PlanTripStartGeneration() when startGeneration != null:
return startGeneration();case PlanTripRetryGeneration() when retryGeneration != null:
return retryGeneration();case PlanTripCreateTrip() when createTrip != null:
return createTrip();case PlanTripBackToProposals() when backToProposals != null:
return backToProposals();case PlanTripUpdateReviewDates() when updateReviewDates != null:
return updateReviewDates(_that.start,_that.end);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loadPersonalization,required TResult Function()  nextStep,required TResult Function()  previousStep,required TResult Function( int step)  goToStep,required TResult Function( DateMode mode)  setDateMode,required TResult Function( DateTime start,  DateTime end)  setExactDates,required TResult Function( int month,  int year)  setMonthPreference,required TResult Function( DurationPreset preset)  setFlexibleDuration,required TResult Function( int? adults,  int? children,  int? babies)  setTravelerCounts,required TResult Function( BudgetPreset? preset)  setBudgetPreset,required TResult Function( String city)  setOriginCity,required TResult Function( String query)  searchOrigin,required TResult Function( String query)  searchDestination,required TResult Function( LocationResult location)  selectManualDestination,required TResult Function()  requestAiSuggestions,required TResult Function( AiDestination destination)  selectAiDestination,required TResult Function( int index)  swipeProposal,required TResult Function()  startGeneration,required TResult Function()  retryGeneration,required TResult Function()  createTrip,required TResult Function()  backToProposals,required TResult Function( DateTime start,  DateTime end)  updateReviewDates,}) {final _that = this;
switch (_that) {
case PlanTripLoadPersonalization():
return loadPersonalization();case PlanTripNextStep():
return nextStep();case PlanTripPreviousStep():
return previousStep();case PlanTripGoToStep():
return goToStep(_that.step);case PlanTripSetDateMode():
return setDateMode(_that.mode);case PlanTripSetExactDates():
return setExactDates(_that.start,_that.end);case PlanTripSetMonthPreference():
return setMonthPreference(_that.month,_that.year);case PlanTripSetFlexibleDuration():
return setFlexibleDuration(_that.preset);case PlanTripSetTravelerCounts():
return setTravelerCounts(_that.adults,_that.children,_that.babies);case PlanTripSetBudgetPreset():
return setBudgetPreset(_that.preset);case PlanTripSetOriginCity():
return setOriginCity(_that.city);case PlanTripSearchOrigin():
return searchOrigin(_that.query);case PlanTripSearchDestination():
return searchDestination(_that.query);case PlanTripSelectManualDestination():
return selectManualDestination(_that.location);case PlanTripRequestAiSuggestions():
return requestAiSuggestions();case PlanTripSelectAiDestination():
return selectAiDestination(_that.destination);case PlanTripSwipeProposal():
return swipeProposal(_that.index);case PlanTripStartGeneration():
return startGeneration();case PlanTripRetryGeneration():
return retryGeneration();case PlanTripCreateTrip():
return createTrip();case PlanTripBackToProposals():
return backToProposals();case PlanTripUpdateReviewDates():
return updateReviewDates(_that.start,_that.end);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loadPersonalization,TResult? Function()?  nextStep,TResult? Function()?  previousStep,TResult? Function( int step)?  goToStep,TResult? Function( DateMode mode)?  setDateMode,TResult? Function( DateTime start,  DateTime end)?  setExactDates,TResult? Function( int month,  int year)?  setMonthPreference,TResult? Function( DurationPreset preset)?  setFlexibleDuration,TResult? Function( int? adults,  int? children,  int? babies)?  setTravelerCounts,TResult? Function( BudgetPreset? preset)?  setBudgetPreset,TResult? Function( String city)?  setOriginCity,TResult? Function( String query)?  searchOrigin,TResult? Function( String query)?  searchDestination,TResult? Function( LocationResult location)?  selectManualDestination,TResult? Function()?  requestAiSuggestions,TResult? Function( AiDestination destination)?  selectAiDestination,TResult? Function( int index)?  swipeProposal,TResult? Function()?  startGeneration,TResult? Function()?  retryGeneration,TResult? Function()?  createTrip,TResult? Function()?  backToProposals,TResult? Function( DateTime start,  DateTime end)?  updateReviewDates,}) {final _that = this;
switch (_that) {
case PlanTripLoadPersonalization() when loadPersonalization != null:
return loadPersonalization();case PlanTripNextStep() when nextStep != null:
return nextStep();case PlanTripPreviousStep() when previousStep != null:
return previousStep();case PlanTripGoToStep() when goToStep != null:
return goToStep(_that.step);case PlanTripSetDateMode() when setDateMode != null:
return setDateMode(_that.mode);case PlanTripSetExactDates() when setExactDates != null:
return setExactDates(_that.start,_that.end);case PlanTripSetMonthPreference() when setMonthPreference != null:
return setMonthPreference(_that.month,_that.year);case PlanTripSetFlexibleDuration() when setFlexibleDuration != null:
return setFlexibleDuration(_that.preset);case PlanTripSetTravelerCounts() when setTravelerCounts != null:
return setTravelerCounts(_that.adults,_that.children,_that.babies);case PlanTripSetBudgetPreset() when setBudgetPreset != null:
return setBudgetPreset(_that.preset);case PlanTripSetOriginCity() when setOriginCity != null:
return setOriginCity(_that.city);case PlanTripSearchOrigin() when searchOrigin != null:
return searchOrigin(_that.query);case PlanTripSearchDestination() when searchDestination != null:
return searchDestination(_that.query);case PlanTripSelectManualDestination() when selectManualDestination != null:
return selectManualDestination(_that.location);case PlanTripRequestAiSuggestions() when requestAiSuggestions != null:
return requestAiSuggestions();case PlanTripSelectAiDestination() when selectAiDestination != null:
return selectAiDestination(_that.destination);case PlanTripSwipeProposal() when swipeProposal != null:
return swipeProposal(_that.index);case PlanTripStartGeneration() when startGeneration != null:
return startGeneration();case PlanTripRetryGeneration() when retryGeneration != null:
return retryGeneration();case PlanTripCreateTrip() when createTrip != null:
return createTrip();case PlanTripBackToProposals() when backToProposals != null:
return backToProposals();case PlanTripUpdateReviewDates() when updateReviewDates != null:
return updateReviewDates(_that.start,_that.end);case _:
  return null;

}
}

}

/// @nodoc


class PlanTripLoadPersonalization implements PlanTripEvent {
  const PlanTripLoadPersonalization();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlanTripLoadPersonalization);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PlanTripEvent.loadPersonalization()';
}


}




/// @nodoc


class PlanTripNextStep implements PlanTripEvent {
  const PlanTripNextStep();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlanTripNextStep);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PlanTripEvent.nextStep()';
}


}




/// @nodoc


class PlanTripPreviousStep implements PlanTripEvent {
  const PlanTripPreviousStep();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlanTripPreviousStep);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PlanTripEvent.previousStep()';
}


}




/// @nodoc


class PlanTripGoToStep implements PlanTripEvent {
  const PlanTripGoToStep(this.step);
  

 final  int step;

/// Create a copy of PlanTripEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlanTripGoToStepCopyWith<PlanTripGoToStep> get copyWith => _$PlanTripGoToStepCopyWithImpl<PlanTripGoToStep>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlanTripGoToStep&&(identical(other.step, step) || other.step == step));
}


@override
int get hashCode => Object.hash(runtimeType,step);

@override
String toString() {
  return 'PlanTripEvent.goToStep(step: $step)';
}


}

/// @nodoc
abstract mixin class $PlanTripGoToStepCopyWith<$Res> implements $PlanTripEventCopyWith<$Res> {
  factory $PlanTripGoToStepCopyWith(PlanTripGoToStep value, $Res Function(PlanTripGoToStep) _then) = _$PlanTripGoToStepCopyWithImpl;
@useResult
$Res call({
 int step
});




}
/// @nodoc
class _$PlanTripGoToStepCopyWithImpl<$Res>
    implements $PlanTripGoToStepCopyWith<$Res> {
  _$PlanTripGoToStepCopyWithImpl(this._self, this._then);

  final PlanTripGoToStep _self;
  final $Res Function(PlanTripGoToStep) _then;

/// Create a copy of PlanTripEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? step = null,}) {
  return _then(PlanTripGoToStep(
null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class PlanTripSetDateMode implements PlanTripEvent {
  const PlanTripSetDateMode(this.mode);
  

 final  DateMode mode;

/// Create a copy of PlanTripEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlanTripSetDateModeCopyWith<PlanTripSetDateMode> get copyWith => _$PlanTripSetDateModeCopyWithImpl<PlanTripSetDateMode>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlanTripSetDateMode&&(identical(other.mode, mode) || other.mode == mode));
}


@override
int get hashCode => Object.hash(runtimeType,mode);

@override
String toString() {
  return 'PlanTripEvent.setDateMode(mode: $mode)';
}


}

/// @nodoc
abstract mixin class $PlanTripSetDateModeCopyWith<$Res> implements $PlanTripEventCopyWith<$Res> {
  factory $PlanTripSetDateModeCopyWith(PlanTripSetDateMode value, $Res Function(PlanTripSetDateMode) _then) = _$PlanTripSetDateModeCopyWithImpl;
@useResult
$Res call({
 DateMode mode
});




}
/// @nodoc
class _$PlanTripSetDateModeCopyWithImpl<$Res>
    implements $PlanTripSetDateModeCopyWith<$Res> {
  _$PlanTripSetDateModeCopyWithImpl(this._self, this._then);

  final PlanTripSetDateMode _self;
  final $Res Function(PlanTripSetDateMode) _then;

/// Create a copy of PlanTripEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? mode = null,}) {
  return _then(PlanTripSetDateMode(
null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as DateMode,
  ));
}


}

/// @nodoc


class PlanTripSetExactDates implements PlanTripEvent {
  const PlanTripSetExactDates(this.start, this.end);
  

 final  DateTime start;
 final  DateTime end;

/// Create a copy of PlanTripEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlanTripSetExactDatesCopyWith<PlanTripSetExactDates> get copyWith => _$PlanTripSetExactDatesCopyWithImpl<PlanTripSetExactDates>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlanTripSetExactDates&&(identical(other.start, start) || other.start == start)&&(identical(other.end, end) || other.end == end));
}


@override
int get hashCode => Object.hash(runtimeType,start,end);

@override
String toString() {
  return 'PlanTripEvent.setExactDates(start: $start, end: $end)';
}


}

/// @nodoc
abstract mixin class $PlanTripSetExactDatesCopyWith<$Res> implements $PlanTripEventCopyWith<$Res> {
  factory $PlanTripSetExactDatesCopyWith(PlanTripSetExactDates value, $Res Function(PlanTripSetExactDates) _then) = _$PlanTripSetExactDatesCopyWithImpl;
@useResult
$Res call({
 DateTime start, DateTime end
});




}
/// @nodoc
class _$PlanTripSetExactDatesCopyWithImpl<$Res>
    implements $PlanTripSetExactDatesCopyWith<$Res> {
  _$PlanTripSetExactDatesCopyWithImpl(this._self, this._then);

  final PlanTripSetExactDates _self;
  final $Res Function(PlanTripSetExactDates) _then;

/// Create a copy of PlanTripEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? start = null,Object? end = null,}) {
  return _then(PlanTripSetExactDates(
null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as DateTime,null == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc


class PlanTripSetMonthPreference implements PlanTripEvent {
  const PlanTripSetMonthPreference(this.month, this.year);
  

 final  int month;
 final  int year;

/// Create a copy of PlanTripEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlanTripSetMonthPreferenceCopyWith<PlanTripSetMonthPreference> get copyWith => _$PlanTripSetMonthPreferenceCopyWithImpl<PlanTripSetMonthPreference>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlanTripSetMonthPreference&&(identical(other.month, month) || other.month == month)&&(identical(other.year, year) || other.year == year));
}


@override
int get hashCode => Object.hash(runtimeType,month,year);

@override
String toString() {
  return 'PlanTripEvent.setMonthPreference(month: $month, year: $year)';
}


}

/// @nodoc
abstract mixin class $PlanTripSetMonthPreferenceCopyWith<$Res> implements $PlanTripEventCopyWith<$Res> {
  factory $PlanTripSetMonthPreferenceCopyWith(PlanTripSetMonthPreference value, $Res Function(PlanTripSetMonthPreference) _then) = _$PlanTripSetMonthPreferenceCopyWithImpl;
@useResult
$Res call({
 int month, int year
});




}
/// @nodoc
class _$PlanTripSetMonthPreferenceCopyWithImpl<$Res>
    implements $PlanTripSetMonthPreferenceCopyWith<$Res> {
  _$PlanTripSetMonthPreferenceCopyWithImpl(this._self, this._then);

  final PlanTripSetMonthPreference _self;
  final $Res Function(PlanTripSetMonthPreference) _then;

/// Create a copy of PlanTripEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? month = null,Object? year = null,}) {
  return _then(PlanTripSetMonthPreference(
null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as int,null == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class PlanTripSetFlexibleDuration implements PlanTripEvent {
  const PlanTripSetFlexibleDuration(this.preset);
  

 final  DurationPreset preset;

/// Create a copy of PlanTripEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlanTripSetFlexibleDurationCopyWith<PlanTripSetFlexibleDuration> get copyWith => _$PlanTripSetFlexibleDurationCopyWithImpl<PlanTripSetFlexibleDuration>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlanTripSetFlexibleDuration&&(identical(other.preset, preset) || other.preset == preset));
}


@override
int get hashCode => Object.hash(runtimeType,preset);

@override
String toString() {
  return 'PlanTripEvent.setFlexibleDuration(preset: $preset)';
}


}

/// @nodoc
abstract mixin class $PlanTripSetFlexibleDurationCopyWith<$Res> implements $PlanTripEventCopyWith<$Res> {
  factory $PlanTripSetFlexibleDurationCopyWith(PlanTripSetFlexibleDuration value, $Res Function(PlanTripSetFlexibleDuration) _then) = _$PlanTripSetFlexibleDurationCopyWithImpl;
@useResult
$Res call({
 DurationPreset preset
});




}
/// @nodoc
class _$PlanTripSetFlexibleDurationCopyWithImpl<$Res>
    implements $PlanTripSetFlexibleDurationCopyWith<$Res> {
  _$PlanTripSetFlexibleDurationCopyWithImpl(this._self, this._then);

  final PlanTripSetFlexibleDuration _self;
  final $Res Function(PlanTripSetFlexibleDuration) _then;

/// Create a copy of PlanTripEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? preset = null,}) {
  return _then(PlanTripSetFlexibleDuration(
null == preset ? _self.preset : preset // ignore: cast_nullable_to_non_nullable
as DurationPreset,
  ));
}


}

/// @nodoc


class PlanTripSetTravelerCounts implements PlanTripEvent {
  const PlanTripSetTravelerCounts({this.adults, this.children, this.babies});
  

 final  int? adults;
 final  int? children;
 final  int? babies;

/// Create a copy of PlanTripEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlanTripSetTravelerCountsCopyWith<PlanTripSetTravelerCounts> get copyWith => _$PlanTripSetTravelerCountsCopyWithImpl<PlanTripSetTravelerCounts>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlanTripSetTravelerCounts&&(identical(other.adults, adults) || other.adults == adults)&&(identical(other.children, children) || other.children == children)&&(identical(other.babies, babies) || other.babies == babies));
}


@override
int get hashCode => Object.hash(runtimeType,adults,children,babies);

@override
String toString() {
  return 'PlanTripEvent.setTravelerCounts(adults: $adults, children: $children, babies: $babies)';
}


}

/// @nodoc
abstract mixin class $PlanTripSetTravelerCountsCopyWith<$Res> implements $PlanTripEventCopyWith<$Res> {
  factory $PlanTripSetTravelerCountsCopyWith(PlanTripSetTravelerCounts value, $Res Function(PlanTripSetTravelerCounts) _then) = _$PlanTripSetTravelerCountsCopyWithImpl;
@useResult
$Res call({
 int? adults, int? children, int? babies
});




}
/// @nodoc
class _$PlanTripSetTravelerCountsCopyWithImpl<$Res>
    implements $PlanTripSetTravelerCountsCopyWith<$Res> {
  _$PlanTripSetTravelerCountsCopyWithImpl(this._self, this._then);

  final PlanTripSetTravelerCounts _self;
  final $Res Function(PlanTripSetTravelerCounts) _then;

/// Create a copy of PlanTripEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? adults = freezed,Object? children = freezed,Object? babies = freezed,}) {
  return _then(PlanTripSetTravelerCounts(
adults: freezed == adults ? _self.adults : adults // ignore: cast_nullable_to_non_nullable
as int?,children: freezed == children ? _self.children : children // ignore: cast_nullable_to_non_nullable
as int?,babies: freezed == babies ? _self.babies : babies // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc


class PlanTripSetBudgetPreset implements PlanTripEvent {
  const PlanTripSetBudgetPreset(this.preset);
  

 final  BudgetPreset? preset;

/// Create a copy of PlanTripEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlanTripSetBudgetPresetCopyWith<PlanTripSetBudgetPreset> get copyWith => _$PlanTripSetBudgetPresetCopyWithImpl<PlanTripSetBudgetPreset>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlanTripSetBudgetPreset&&(identical(other.preset, preset) || other.preset == preset));
}


@override
int get hashCode => Object.hash(runtimeType,preset);

@override
String toString() {
  return 'PlanTripEvent.setBudgetPreset(preset: $preset)';
}


}

/// @nodoc
abstract mixin class $PlanTripSetBudgetPresetCopyWith<$Res> implements $PlanTripEventCopyWith<$Res> {
  factory $PlanTripSetBudgetPresetCopyWith(PlanTripSetBudgetPreset value, $Res Function(PlanTripSetBudgetPreset) _then) = _$PlanTripSetBudgetPresetCopyWithImpl;
@useResult
$Res call({
 BudgetPreset? preset
});




}
/// @nodoc
class _$PlanTripSetBudgetPresetCopyWithImpl<$Res>
    implements $PlanTripSetBudgetPresetCopyWith<$Res> {
  _$PlanTripSetBudgetPresetCopyWithImpl(this._self, this._then);

  final PlanTripSetBudgetPreset _self;
  final $Res Function(PlanTripSetBudgetPreset) _then;

/// Create a copy of PlanTripEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? preset = freezed,}) {
  return _then(PlanTripSetBudgetPreset(
freezed == preset ? _self.preset : preset // ignore: cast_nullable_to_non_nullable
as BudgetPreset?,
  ));
}


}

/// @nodoc


class PlanTripSetOriginCity implements PlanTripEvent {
  const PlanTripSetOriginCity(this.city);
  

 final  String city;

/// Create a copy of PlanTripEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlanTripSetOriginCityCopyWith<PlanTripSetOriginCity> get copyWith => _$PlanTripSetOriginCityCopyWithImpl<PlanTripSetOriginCity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlanTripSetOriginCity&&(identical(other.city, city) || other.city == city));
}


@override
int get hashCode => Object.hash(runtimeType,city);

@override
String toString() {
  return 'PlanTripEvent.setOriginCity(city: $city)';
}


}

/// @nodoc
abstract mixin class $PlanTripSetOriginCityCopyWith<$Res> implements $PlanTripEventCopyWith<$Res> {
  factory $PlanTripSetOriginCityCopyWith(PlanTripSetOriginCity value, $Res Function(PlanTripSetOriginCity) _then) = _$PlanTripSetOriginCityCopyWithImpl;
@useResult
$Res call({
 String city
});




}
/// @nodoc
class _$PlanTripSetOriginCityCopyWithImpl<$Res>
    implements $PlanTripSetOriginCityCopyWith<$Res> {
  _$PlanTripSetOriginCityCopyWithImpl(this._self, this._then);

  final PlanTripSetOriginCity _self;
  final $Res Function(PlanTripSetOriginCity) _then;

/// Create a copy of PlanTripEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? city = null,}) {
  return _then(PlanTripSetOriginCity(
null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class PlanTripSearchOrigin implements PlanTripEvent {
  const PlanTripSearchOrigin(this.query);
  

 final  String query;

/// Create a copy of PlanTripEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlanTripSearchOriginCopyWith<PlanTripSearchOrigin> get copyWith => _$PlanTripSearchOriginCopyWithImpl<PlanTripSearchOrigin>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlanTripSearchOrigin&&(identical(other.query, query) || other.query == query));
}


@override
int get hashCode => Object.hash(runtimeType,query);

@override
String toString() {
  return 'PlanTripEvent.searchOrigin(query: $query)';
}


}

/// @nodoc
abstract mixin class $PlanTripSearchOriginCopyWith<$Res> implements $PlanTripEventCopyWith<$Res> {
  factory $PlanTripSearchOriginCopyWith(PlanTripSearchOrigin value, $Res Function(PlanTripSearchOrigin) _then) = _$PlanTripSearchOriginCopyWithImpl;
@useResult
$Res call({
 String query
});




}
/// @nodoc
class _$PlanTripSearchOriginCopyWithImpl<$Res>
    implements $PlanTripSearchOriginCopyWith<$Res> {
  _$PlanTripSearchOriginCopyWithImpl(this._self, this._then);

  final PlanTripSearchOrigin _self;
  final $Res Function(PlanTripSearchOrigin) _then;

/// Create a copy of PlanTripEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? query = null,}) {
  return _then(PlanTripSearchOrigin(
null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class PlanTripSearchDestination implements PlanTripEvent {
  const PlanTripSearchDestination(this.query);
  

 final  String query;

/// Create a copy of PlanTripEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlanTripSearchDestinationCopyWith<PlanTripSearchDestination> get copyWith => _$PlanTripSearchDestinationCopyWithImpl<PlanTripSearchDestination>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlanTripSearchDestination&&(identical(other.query, query) || other.query == query));
}


@override
int get hashCode => Object.hash(runtimeType,query);

@override
String toString() {
  return 'PlanTripEvent.searchDestination(query: $query)';
}


}

/// @nodoc
abstract mixin class $PlanTripSearchDestinationCopyWith<$Res> implements $PlanTripEventCopyWith<$Res> {
  factory $PlanTripSearchDestinationCopyWith(PlanTripSearchDestination value, $Res Function(PlanTripSearchDestination) _then) = _$PlanTripSearchDestinationCopyWithImpl;
@useResult
$Res call({
 String query
});




}
/// @nodoc
class _$PlanTripSearchDestinationCopyWithImpl<$Res>
    implements $PlanTripSearchDestinationCopyWith<$Res> {
  _$PlanTripSearchDestinationCopyWithImpl(this._self, this._then);

  final PlanTripSearchDestination _self;
  final $Res Function(PlanTripSearchDestination) _then;

/// Create a copy of PlanTripEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? query = null,}) {
  return _then(PlanTripSearchDestination(
null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class PlanTripSelectManualDestination implements PlanTripEvent {
  const PlanTripSelectManualDestination(this.location);
  

 final  LocationResult location;

/// Create a copy of PlanTripEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlanTripSelectManualDestinationCopyWith<PlanTripSelectManualDestination> get copyWith => _$PlanTripSelectManualDestinationCopyWithImpl<PlanTripSelectManualDestination>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlanTripSelectManualDestination&&(identical(other.location, location) || other.location == location));
}


@override
int get hashCode => Object.hash(runtimeType,location);

@override
String toString() {
  return 'PlanTripEvent.selectManualDestination(location: $location)';
}


}

/// @nodoc
abstract mixin class $PlanTripSelectManualDestinationCopyWith<$Res> implements $PlanTripEventCopyWith<$Res> {
  factory $PlanTripSelectManualDestinationCopyWith(PlanTripSelectManualDestination value, $Res Function(PlanTripSelectManualDestination) _then) = _$PlanTripSelectManualDestinationCopyWithImpl;
@useResult
$Res call({
 LocationResult location
});


$LocationResultCopyWith<$Res> get location;

}
/// @nodoc
class _$PlanTripSelectManualDestinationCopyWithImpl<$Res>
    implements $PlanTripSelectManualDestinationCopyWith<$Res> {
  _$PlanTripSelectManualDestinationCopyWithImpl(this._self, this._then);

  final PlanTripSelectManualDestination _self;
  final $Res Function(PlanTripSelectManualDestination) _then;

/// Create a copy of PlanTripEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? location = null,}) {
  return _then(PlanTripSelectManualDestination(
null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as LocationResult,
  ));
}

/// Create a copy of PlanTripEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LocationResultCopyWith<$Res> get location {
  
  return $LocationResultCopyWith<$Res>(_self.location, (value) {
    return _then(_self.copyWith(location: value));
  });
}
}

/// @nodoc


class PlanTripRequestAiSuggestions implements PlanTripEvent {
  const PlanTripRequestAiSuggestions();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlanTripRequestAiSuggestions);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PlanTripEvent.requestAiSuggestions()';
}


}




/// @nodoc


class PlanTripSelectAiDestination implements PlanTripEvent {
  const PlanTripSelectAiDestination(this.destination);
  

 final  AiDestination destination;

/// Create a copy of PlanTripEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlanTripSelectAiDestinationCopyWith<PlanTripSelectAiDestination> get copyWith => _$PlanTripSelectAiDestinationCopyWithImpl<PlanTripSelectAiDestination>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlanTripSelectAiDestination&&(identical(other.destination, destination) || other.destination == destination));
}


@override
int get hashCode => Object.hash(runtimeType,destination);

@override
String toString() {
  return 'PlanTripEvent.selectAiDestination(destination: $destination)';
}


}

/// @nodoc
abstract mixin class $PlanTripSelectAiDestinationCopyWith<$Res> implements $PlanTripEventCopyWith<$Res> {
  factory $PlanTripSelectAiDestinationCopyWith(PlanTripSelectAiDestination value, $Res Function(PlanTripSelectAiDestination) _then) = _$PlanTripSelectAiDestinationCopyWithImpl;
@useResult
$Res call({
 AiDestination destination
});


$AiDestinationCopyWith<$Res> get destination;

}
/// @nodoc
class _$PlanTripSelectAiDestinationCopyWithImpl<$Res>
    implements $PlanTripSelectAiDestinationCopyWith<$Res> {
  _$PlanTripSelectAiDestinationCopyWithImpl(this._self, this._then);

  final PlanTripSelectAiDestination _self;
  final $Res Function(PlanTripSelectAiDestination) _then;

/// Create a copy of PlanTripEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? destination = null,}) {
  return _then(PlanTripSelectAiDestination(
null == destination ? _self.destination : destination // ignore: cast_nullable_to_non_nullable
as AiDestination,
  ));
}

/// Create a copy of PlanTripEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AiDestinationCopyWith<$Res> get destination {
  
  return $AiDestinationCopyWith<$Res>(_self.destination, (value) {
    return _then(_self.copyWith(destination: value));
  });
}
}

/// @nodoc


class PlanTripSwipeProposal implements PlanTripEvent {
  const PlanTripSwipeProposal(this.index);
  

 final  int index;

/// Create a copy of PlanTripEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlanTripSwipeProposalCopyWith<PlanTripSwipeProposal> get copyWith => _$PlanTripSwipeProposalCopyWithImpl<PlanTripSwipeProposal>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlanTripSwipeProposal&&(identical(other.index, index) || other.index == index));
}


@override
int get hashCode => Object.hash(runtimeType,index);

@override
String toString() {
  return 'PlanTripEvent.swipeProposal(index: $index)';
}


}

/// @nodoc
abstract mixin class $PlanTripSwipeProposalCopyWith<$Res> implements $PlanTripEventCopyWith<$Res> {
  factory $PlanTripSwipeProposalCopyWith(PlanTripSwipeProposal value, $Res Function(PlanTripSwipeProposal) _then) = _$PlanTripSwipeProposalCopyWithImpl;
@useResult
$Res call({
 int index
});




}
/// @nodoc
class _$PlanTripSwipeProposalCopyWithImpl<$Res>
    implements $PlanTripSwipeProposalCopyWith<$Res> {
  _$PlanTripSwipeProposalCopyWithImpl(this._self, this._then);

  final PlanTripSwipeProposal _self;
  final $Res Function(PlanTripSwipeProposal) _then;

/// Create a copy of PlanTripEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? index = null,}) {
  return _then(PlanTripSwipeProposal(
null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class PlanTripStartGeneration implements PlanTripEvent {
  const PlanTripStartGeneration();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlanTripStartGeneration);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PlanTripEvent.startGeneration()';
}


}




/// @nodoc


class PlanTripRetryGeneration implements PlanTripEvent {
  const PlanTripRetryGeneration();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlanTripRetryGeneration);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PlanTripEvent.retryGeneration()';
}


}




/// @nodoc


class PlanTripCreateTrip implements PlanTripEvent {
  const PlanTripCreateTrip();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlanTripCreateTrip);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PlanTripEvent.createTrip()';
}


}




/// @nodoc


class PlanTripBackToProposals implements PlanTripEvent {
  const PlanTripBackToProposals();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlanTripBackToProposals);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PlanTripEvent.backToProposals()';
}


}




/// @nodoc


class PlanTripUpdateReviewDates implements PlanTripEvent {
  const PlanTripUpdateReviewDates(this.start, this.end);
  

 final  DateTime start;
 final  DateTime end;

/// Create a copy of PlanTripEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlanTripUpdateReviewDatesCopyWith<PlanTripUpdateReviewDates> get copyWith => _$PlanTripUpdateReviewDatesCopyWithImpl<PlanTripUpdateReviewDates>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlanTripUpdateReviewDates&&(identical(other.start, start) || other.start == start)&&(identical(other.end, end) || other.end == end));
}


@override
int get hashCode => Object.hash(runtimeType,start,end);

@override
String toString() {
  return 'PlanTripEvent.updateReviewDates(start: $start, end: $end)';
}


}

/// @nodoc
abstract mixin class $PlanTripUpdateReviewDatesCopyWith<$Res> implements $PlanTripEventCopyWith<$Res> {
  factory $PlanTripUpdateReviewDatesCopyWith(PlanTripUpdateReviewDates value, $Res Function(PlanTripUpdateReviewDates) _then) = _$PlanTripUpdateReviewDatesCopyWithImpl;
@useResult
$Res call({
 DateTime start, DateTime end
});




}
/// @nodoc
class _$PlanTripUpdateReviewDatesCopyWithImpl<$Res>
    implements $PlanTripUpdateReviewDatesCopyWith<$Res> {
  _$PlanTripUpdateReviewDatesCopyWithImpl(this._self, this._then);

  final PlanTripUpdateReviewDates _self;
  final $Res Function(PlanTripUpdateReviewDates) _then;

/// Create a copy of PlanTripEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? start = null,Object? end = null,}) {
  return _then(PlanTripUpdateReviewDates(
null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as DateTime,null == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc
mixin _$PlanTripState {

// Navigation
 int get currentStep;// Step 0 — Dates
 DateMode get dateMode; DateTime? get startDate; DateTime? get endDate; int? get preferredMonth; int? get preferredYear; DurationPreset? get flexibleDuration;// Step 1 — Travelers + Budget
 int get nbAdults; int get nbChildren; int get nbBabies; BudgetPreset? get budgetPreset; String? get originCity; List<LocationResult> get originSearchResults;// Step 2 — Destination
 List<LocationResult> get searchResults; bool get isSearching; LocationResult? get selectedManualDestination; List<AiDestination> get aiSuggestions; bool get isLoadingAiSuggestions; AiDestination? get selectedAiDestination;// Step 4 — Generation
 Map<String, StepStatus> get generationSteps; double get generationProgress; String? get generationMessage; TripPlan? get generatedPlan; String? get generationError;// Step 5 — Review / Creation
 bool get isCreating; String? get createdTripId;// Meta
 bool get isManualFlow; AppError? get error;
/// Create a copy of PlanTripState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlanTripStateCopyWith<PlanTripState> get copyWith => _$PlanTripStateCopyWithImpl<PlanTripState>(this as PlanTripState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlanTripState&&(identical(other.currentStep, currentStep) || other.currentStep == currentStep)&&(identical(other.dateMode, dateMode) || other.dateMode == dateMode)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.preferredMonth, preferredMonth) || other.preferredMonth == preferredMonth)&&(identical(other.preferredYear, preferredYear) || other.preferredYear == preferredYear)&&(identical(other.flexibleDuration, flexibleDuration) || other.flexibleDuration == flexibleDuration)&&(identical(other.nbAdults, nbAdults) || other.nbAdults == nbAdults)&&(identical(other.nbChildren, nbChildren) || other.nbChildren == nbChildren)&&(identical(other.nbBabies, nbBabies) || other.nbBabies == nbBabies)&&(identical(other.budgetPreset, budgetPreset) || other.budgetPreset == budgetPreset)&&(identical(other.originCity, originCity) || other.originCity == originCity)&&const DeepCollectionEquality().equals(other.originSearchResults, originSearchResults)&&const DeepCollectionEquality().equals(other.searchResults, searchResults)&&(identical(other.isSearching, isSearching) || other.isSearching == isSearching)&&(identical(other.selectedManualDestination, selectedManualDestination) || other.selectedManualDestination == selectedManualDestination)&&const DeepCollectionEquality().equals(other.aiSuggestions, aiSuggestions)&&(identical(other.isLoadingAiSuggestions, isLoadingAiSuggestions) || other.isLoadingAiSuggestions == isLoadingAiSuggestions)&&(identical(other.selectedAiDestination, selectedAiDestination) || other.selectedAiDestination == selectedAiDestination)&&const DeepCollectionEquality().equals(other.generationSteps, generationSteps)&&(identical(other.generationProgress, generationProgress) || other.generationProgress == generationProgress)&&(identical(other.generationMessage, generationMessage) || other.generationMessage == generationMessage)&&(identical(other.generatedPlan, generatedPlan) || other.generatedPlan == generatedPlan)&&(identical(other.generationError, generationError) || other.generationError == generationError)&&(identical(other.isCreating, isCreating) || other.isCreating == isCreating)&&(identical(other.createdTripId, createdTripId) || other.createdTripId == createdTripId)&&(identical(other.isManualFlow, isManualFlow) || other.isManualFlow == isManualFlow)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hashAll([runtimeType,currentStep,dateMode,startDate,endDate,preferredMonth,preferredYear,flexibleDuration,nbAdults,nbChildren,nbBabies,budgetPreset,originCity,const DeepCollectionEquality().hash(originSearchResults),const DeepCollectionEquality().hash(searchResults),isSearching,selectedManualDestination,const DeepCollectionEquality().hash(aiSuggestions),isLoadingAiSuggestions,selectedAiDestination,const DeepCollectionEquality().hash(generationSteps),generationProgress,generationMessage,generatedPlan,generationError,isCreating,createdTripId,isManualFlow,error]);

@override
String toString() {
  return 'PlanTripState(currentStep: $currentStep, dateMode: $dateMode, startDate: $startDate, endDate: $endDate, preferredMonth: $preferredMonth, preferredYear: $preferredYear, flexibleDuration: $flexibleDuration, nbAdults: $nbAdults, nbChildren: $nbChildren, nbBabies: $nbBabies, budgetPreset: $budgetPreset, originCity: $originCity, originSearchResults: $originSearchResults, searchResults: $searchResults, isSearching: $isSearching, selectedManualDestination: $selectedManualDestination, aiSuggestions: $aiSuggestions, isLoadingAiSuggestions: $isLoadingAiSuggestions, selectedAiDestination: $selectedAiDestination, generationSteps: $generationSteps, generationProgress: $generationProgress, generationMessage: $generationMessage, generatedPlan: $generatedPlan, generationError: $generationError, isCreating: $isCreating, createdTripId: $createdTripId, isManualFlow: $isManualFlow, error: $error)';
}


}

/// @nodoc
abstract mixin class $PlanTripStateCopyWith<$Res>  {
  factory $PlanTripStateCopyWith(PlanTripState value, $Res Function(PlanTripState) _then) = _$PlanTripStateCopyWithImpl;
@useResult
$Res call({
 int currentStep, DateMode dateMode, DateTime? startDate, DateTime? endDate, int? preferredMonth, int? preferredYear, DurationPreset? flexibleDuration, int nbAdults, int nbChildren, int nbBabies, BudgetPreset? budgetPreset, String? originCity, List<LocationResult> originSearchResults, List<LocationResult> searchResults, bool isSearching, LocationResult? selectedManualDestination, List<AiDestination> aiSuggestions, bool isLoadingAiSuggestions, AiDestination? selectedAiDestination, Map<String, StepStatus> generationSteps, double generationProgress, String? generationMessage, TripPlan? generatedPlan, String? generationError, bool isCreating, String? createdTripId, bool isManualFlow, AppError? error
});


$LocationResultCopyWith<$Res>? get selectedManualDestination;$AiDestinationCopyWith<$Res>? get selectedAiDestination;$TripPlanCopyWith<$Res>? get generatedPlan;

}
/// @nodoc
class _$PlanTripStateCopyWithImpl<$Res>
    implements $PlanTripStateCopyWith<$Res> {
  _$PlanTripStateCopyWithImpl(this._self, this._then);

  final PlanTripState _self;
  final $Res Function(PlanTripState) _then;

/// Create a copy of PlanTripState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? currentStep = null,Object? dateMode = null,Object? startDate = freezed,Object? endDate = freezed,Object? preferredMonth = freezed,Object? preferredYear = freezed,Object? flexibleDuration = freezed,Object? nbAdults = null,Object? nbChildren = null,Object? nbBabies = null,Object? budgetPreset = freezed,Object? originCity = freezed,Object? originSearchResults = null,Object? searchResults = null,Object? isSearching = null,Object? selectedManualDestination = freezed,Object? aiSuggestions = null,Object? isLoadingAiSuggestions = null,Object? selectedAiDestination = freezed,Object? generationSteps = null,Object? generationProgress = null,Object? generationMessage = freezed,Object? generatedPlan = freezed,Object? generationError = freezed,Object? isCreating = null,Object? createdTripId = freezed,Object? isManualFlow = null,Object? error = freezed,}) {
  return _then(_self.copyWith(
currentStep: null == currentStep ? _self.currentStep : currentStep // ignore: cast_nullable_to_non_nullable
as int,dateMode: null == dateMode ? _self.dateMode : dateMode // ignore: cast_nullable_to_non_nullable
as DateMode,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,preferredMonth: freezed == preferredMonth ? _self.preferredMonth : preferredMonth // ignore: cast_nullable_to_non_nullable
as int?,preferredYear: freezed == preferredYear ? _self.preferredYear : preferredYear // ignore: cast_nullable_to_non_nullable
as int?,flexibleDuration: freezed == flexibleDuration ? _self.flexibleDuration : flexibleDuration // ignore: cast_nullable_to_non_nullable
as DurationPreset?,nbAdults: null == nbAdults ? _self.nbAdults : nbAdults // ignore: cast_nullable_to_non_nullable
as int,nbChildren: null == nbChildren ? _self.nbChildren : nbChildren // ignore: cast_nullable_to_non_nullable
as int,nbBabies: null == nbBabies ? _self.nbBabies : nbBabies // ignore: cast_nullable_to_non_nullable
as int,budgetPreset: freezed == budgetPreset ? _self.budgetPreset : budgetPreset // ignore: cast_nullable_to_non_nullable
as BudgetPreset?,originCity: freezed == originCity ? _self.originCity : originCity // ignore: cast_nullable_to_non_nullable
as String?,originSearchResults: null == originSearchResults ? _self.originSearchResults : originSearchResults // ignore: cast_nullable_to_non_nullable
as List<LocationResult>,searchResults: null == searchResults ? _self.searchResults : searchResults // ignore: cast_nullable_to_non_nullable
as List<LocationResult>,isSearching: null == isSearching ? _self.isSearching : isSearching // ignore: cast_nullable_to_non_nullable
as bool,selectedManualDestination: freezed == selectedManualDestination ? _self.selectedManualDestination : selectedManualDestination // ignore: cast_nullable_to_non_nullable
as LocationResult?,aiSuggestions: null == aiSuggestions ? _self.aiSuggestions : aiSuggestions // ignore: cast_nullable_to_non_nullable
as List<AiDestination>,isLoadingAiSuggestions: null == isLoadingAiSuggestions ? _self.isLoadingAiSuggestions : isLoadingAiSuggestions // ignore: cast_nullable_to_non_nullable
as bool,selectedAiDestination: freezed == selectedAiDestination ? _self.selectedAiDestination : selectedAiDestination // ignore: cast_nullable_to_non_nullable
as AiDestination?,generationSteps: null == generationSteps ? _self.generationSteps : generationSteps // ignore: cast_nullable_to_non_nullable
as Map<String, StepStatus>,generationProgress: null == generationProgress ? _self.generationProgress : generationProgress // ignore: cast_nullable_to_non_nullable
as double,generationMessage: freezed == generationMessage ? _self.generationMessage : generationMessage // ignore: cast_nullable_to_non_nullable
as String?,generatedPlan: freezed == generatedPlan ? _self.generatedPlan : generatedPlan // ignore: cast_nullable_to_non_nullable
as TripPlan?,generationError: freezed == generationError ? _self.generationError : generationError // ignore: cast_nullable_to_non_nullable
as String?,isCreating: null == isCreating ? _self.isCreating : isCreating // ignore: cast_nullable_to_non_nullable
as bool,createdTripId: freezed == createdTripId ? _self.createdTripId : createdTripId // ignore: cast_nullable_to_non_nullable
as String?,isManualFlow: null == isManualFlow ? _self.isManualFlow : isManualFlow // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as AppError?,
  ));
}
/// Create a copy of PlanTripState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LocationResultCopyWith<$Res>? get selectedManualDestination {
    if (_self.selectedManualDestination == null) {
    return null;
  }

  return $LocationResultCopyWith<$Res>(_self.selectedManualDestination!, (value) {
    return _then(_self.copyWith(selectedManualDestination: value));
  });
}/// Create a copy of PlanTripState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AiDestinationCopyWith<$Res>? get selectedAiDestination {
    if (_self.selectedAiDestination == null) {
    return null;
  }

  return $AiDestinationCopyWith<$Res>(_self.selectedAiDestination!, (value) {
    return _then(_self.copyWith(selectedAiDestination: value));
  });
}/// Create a copy of PlanTripState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TripPlanCopyWith<$Res>? get generatedPlan {
    if (_self.generatedPlan == null) {
    return null;
  }

  return $TripPlanCopyWith<$Res>(_self.generatedPlan!, (value) {
    return _then(_self.copyWith(generatedPlan: value));
  });
}
}


/// Adds pattern-matching-related methods to [PlanTripState].
extension PlanTripStatePatterns on PlanTripState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlanTripState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlanTripState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlanTripState value)  $default,){
final _that = this;
switch (_that) {
case _PlanTripState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlanTripState value)?  $default,){
final _that = this;
switch (_that) {
case _PlanTripState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int currentStep,  DateMode dateMode,  DateTime? startDate,  DateTime? endDate,  int? preferredMonth,  int? preferredYear,  DurationPreset? flexibleDuration,  int nbAdults,  int nbChildren,  int nbBabies,  BudgetPreset? budgetPreset,  String? originCity,  List<LocationResult> originSearchResults,  List<LocationResult> searchResults,  bool isSearching,  LocationResult? selectedManualDestination,  List<AiDestination> aiSuggestions,  bool isLoadingAiSuggestions,  AiDestination? selectedAiDestination,  Map<String, StepStatus> generationSteps,  double generationProgress,  String? generationMessage,  TripPlan? generatedPlan,  String? generationError,  bool isCreating,  String? createdTripId,  bool isManualFlow,  AppError? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlanTripState() when $default != null:
return $default(_that.currentStep,_that.dateMode,_that.startDate,_that.endDate,_that.preferredMonth,_that.preferredYear,_that.flexibleDuration,_that.nbAdults,_that.nbChildren,_that.nbBabies,_that.budgetPreset,_that.originCity,_that.originSearchResults,_that.searchResults,_that.isSearching,_that.selectedManualDestination,_that.aiSuggestions,_that.isLoadingAiSuggestions,_that.selectedAiDestination,_that.generationSteps,_that.generationProgress,_that.generationMessage,_that.generatedPlan,_that.generationError,_that.isCreating,_that.createdTripId,_that.isManualFlow,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int currentStep,  DateMode dateMode,  DateTime? startDate,  DateTime? endDate,  int? preferredMonth,  int? preferredYear,  DurationPreset? flexibleDuration,  int nbAdults,  int nbChildren,  int nbBabies,  BudgetPreset? budgetPreset,  String? originCity,  List<LocationResult> originSearchResults,  List<LocationResult> searchResults,  bool isSearching,  LocationResult? selectedManualDestination,  List<AiDestination> aiSuggestions,  bool isLoadingAiSuggestions,  AiDestination? selectedAiDestination,  Map<String, StepStatus> generationSteps,  double generationProgress,  String? generationMessage,  TripPlan? generatedPlan,  String? generationError,  bool isCreating,  String? createdTripId,  bool isManualFlow,  AppError? error)  $default,) {final _that = this;
switch (_that) {
case _PlanTripState():
return $default(_that.currentStep,_that.dateMode,_that.startDate,_that.endDate,_that.preferredMonth,_that.preferredYear,_that.flexibleDuration,_that.nbAdults,_that.nbChildren,_that.nbBabies,_that.budgetPreset,_that.originCity,_that.originSearchResults,_that.searchResults,_that.isSearching,_that.selectedManualDestination,_that.aiSuggestions,_that.isLoadingAiSuggestions,_that.selectedAiDestination,_that.generationSteps,_that.generationProgress,_that.generationMessage,_that.generatedPlan,_that.generationError,_that.isCreating,_that.createdTripId,_that.isManualFlow,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int currentStep,  DateMode dateMode,  DateTime? startDate,  DateTime? endDate,  int? preferredMonth,  int? preferredYear,  DurationPreset? flexibleDuration,  int nbAdults,  int nbChildren,  int nbBabies,  BudgetPreset? budgetPreset,  String? originCity,  List<LocationResult> originSearchResults,  List<LocationResult> searchResults,  bool isSearching,  LocationResult? selectedManualDestination,  List<AiDestination> aiSuggestions,  bool isLoadingAiSuggestions,  AiDestination? selectedAiDestination,  Map<String, StepStatus> generationSteps,  double generationProgress,  String? generationMessage,  TripPlan? generatedPlan,  String? generationError,  bool isCreating,  String? createdTripId,  bool isManualFlow,  AppError? error)?  $default,) {final _that = this;
switch (_that) {
case _PlanTripState() when $default != null:
return $default(_that.currentStep,_that.dateMode,_that.startDate,_that.endDate,_that.preferredMonth,_that.preferredYear,_that.flexibleDuration,_that.nbAdults,_that.nbChildren,_that.nbBabies,_that.budgetPreset,_that.originCity,_that.originSearchResults,_that.searchResults,_that.isSearching,_that.selectedManualDestination,_that.aiSuggestions,_that.isLoadingAiSuggestions,_that.selectedAiDestination,_that.generationSteps,_that.generationProgress,_that.generationMessage,_that.generatedPlan,_that.generationError,_that.isCreating,_that.createdTripId,_that.isManualFlow,_that.error);case _:
  return null;

}
}

}

/// @nodoc


class _PlanTripState extends PlanTripState {
  const _PlanTripState({this.currentStep = 0, this.dateMode = DateMode.exact, this.startDate, this.endDate, this.preferredMonth, this.preferredYear, this.flexibleDuration, this.nbAdults = 1, this.nbChildren = 0, this.nbBabies = 0, this.budgetPreset, this.originCity, final  List<LocationResult> originSearchResults = const [], final  List<LocationResult> searchResults = const [], this.isSearching = false, this.selectedManualDestination, final  List<AiDestination> aiSuggestions = const [], this.isLoadingAiSuggestions = false, this.selectedAiDestination, final  Map<String, StepStatus> generationSteps = const {}, this.generationProgress = 0.0, this.generationMessage, this.generatedPlan, this.generationError, this.isCreating = false, this.createdTripId, this.isManualFlow = false, this.error}): _originSearchResults = originSearchResults,_searchResults = searchResults,_aiSuggestions = aiSuggestions,_generationSteps = generationSteps,super._();
  

// Navigation
@override@JsonKey() final  int currentStep;
// Step 0 — Dates
@override@JsonKey() final  DateMode dateMode;
@override final  DateTime? startDate;
@override final  DateTime? endDate;
@override final  int? preferredMonth;
@override final  int? preferredYear;
@override final  DurationPreset? flexibleDuration;
// Step 1 — Travelers + Budget
@override@JsonKey() final  int nbAdults;
@override@JsonKey() final  int nbChildren;
@override@JsonKey() final  int nbBabies;
@override final  BudgetPreset? budgetPreset;
@override final  String? originCity;
 final  List<LocationResult> _originSearchResults;
@override@JsonKey() List<LocationResult> get originSearchResults {
  if (_originSearchResults is EqualUnmodifiableListView) return _originSearchResults;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_originSearchResults);
}

// Step 2 — Destination
 final  List<LocationResult> _searchResults;
// Step 2 — Destination
@override@JsonKey() List<LocationResult> get searchResults {
  if (_searchResults is EqualUnmodifiableListView) return _searchResults;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_searchResults);
}

@override@JsonKey() final  bool isSearching;
@override final  LocationResult? selectedManualDestination;
 final  List<AiDestination> _aiSuggestions;
@override@JsonKey() List<AiDestination> get aiSuggestions {
  if (_aiSuggestions is EqualUnmodifiableListView) return _aiSuggestions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_aiSuggestions);
}

@override@JsonKey() final  bool isLoadingAiSuggestions;
@override final  AiDestination? selectedAiDestination;
// Step 4 — Generation
 final  Map<String, StepStatus> _generationSteps;
// Step 4 — Generation
@override@JsonKey() Map<String, StepStatus> get generationSteps {
  if (_generationSteps is EqualUnmodifiableMapView) return _generationSteps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_generationSteps);
}

@override@JsonKey() final  double generationProgress;
@override final  String? generationMessage;
@override final  TripPlan? generatedPlan;
@override final  String? generationError;
// Step 5 — Review / Creation
@override@JsonKey() final  bool isCreating;
@override final  String? createdTripId;
// Meta
@override@JsonKey() final  bool isManualFlow;
@override final  AppError? error;

/// Create a copy of PlanTripState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlanTripStateCopyWith<_PlanTripState> get copyWith => __$PlanTripStateCopyWithImpl<_PlanTripState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlanTripState&&(identical(other.currentStep, currentStep) || other.currentStep == currentStep)&&(identical(other.dateMode, dateMode) || other.dateMode == dateMode)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.preferredMonth, preferredMonth) || other.preferredMonth == preferredMonth)&&(identical(other.preferredYear, preferredYear) || other.preferredYear == preferredYear)&&(identical(other.flexibleDuration, flexibleDuration) || other.flexibleDuration == flexibleDuration)&&(identical(other.nbAdults, nbAdults) || other.nbAdults == nbAdults)&&(identical(other.nbChildren, nbChildren) || other.nbChildren == nbChildren)&&(identical(other.nbBabies, nbBabies) || other.nbBabies == nbBabies)&&(identical(other.budgetPreset, budgetPreset) || other.budgetPreset == budgetPreset)&&(identical(other.originCity, originCity) || other.originCity == originCity)&&const DeepCollectionEquality().equals(other._originSearchResults, _originSearchResults)&&const DeepCollectionEquality().equals(other._searchResults, _searchResults)&&(identical(other.isSearching, isSearching) || other.isSearching == isSearching)&&(identical(other.selectedManualDestination, selectedManualDestination) || other.selectedManualDestination == selectedManualDestination)&&const DeepCollectionEquality().equals(other._aiSuggestions, _aiSuggestions)&&(identical(other.isLoadingAiSuggestions, isLoadingAiSuggestions) || other.isLoadingAiSuggestions == isLoadingAiSuggestions)&&(identical(other.selectedAiDestination, selectedAiDestination) || other.selectedAiDestination == selectedAiDestination)&&const DeepCollectionEquality().equals(other._generationSteps, _generationSteps)&&(identical(other.generationProgress, generationProgress) || other.generationProgress == generationProgress)&&(identical(other.generationMessage, generationMessage) || other.generationMessage == generationMessage)&&(identical(other.generatedPlan, generatedPlan) || other.generatedPlan == generatedPlan)&&(identical(other.generationError, generationError) || other.generationError == generationError)&&(identical(other.isCreating, isCreating) || other.isCreating == isCreating)&&(identical(other.createdTripId, createdTripId) || other.createdTripId == createdTripId)&&(identical(other.isManualFlow, isManualFlow) || other.isManualFlow == isManualFlow)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hashAll([runtimeType,currentStep,dateMode,startDate,endDate,preferredMonth,preferredYear,flexibleDuration,nbAdults,nbChildren,nbBabies,budgetPreset,originCity,const DeepCollectionEquality().hash(_originSearchResults),const DeepCollectionEquality().hash(_searchResults),isSearching,selectedManualDestination,const DeepCollectionEquality().hash(_aiSuggestions),isLoadingAiSuggestions,selectedAiDestination,const DeepCollectionEquality().hash(_generationSteps),generationProgress,generationMessage,generatedPlan,generationError,isCreating,createdTripId,isManualFlow,error]);

@override
String toString() {
  return 'PlanTripState(currentStep: $currentStep, dateMode: $dateMode, startDate: $startDate, endDate: $endDate, preferredMonth: $preferredMonth, preferredYear: $preferredYear, flexibleDuration: $flexibleDuration, nbAdults: $nbAdults, nbChildren: $nbChildren, nbBabies: $nbBabies, budgetPreset: $budgetPreset, originCity: $originCity, originSearchResults: $originSearchResults, searchResults: $searchResults, isSearching: $isSearching, selectedManualDestination: $selectedManualDestination, aiSuggestions: $aiSuggestions, isLoadingAiSuggestions: $isLoadingAiSuggestions, selectedAiDestination: $selectedAiDestination, generationSteps: $generationSteps, generationProgress: $generationProgress, generationMessage: $generationMessage, generatedPlan: $generatedPlan, generationError: $generationError, isCreating: $isCreating, createdTripId: $createdTripId, isManualFlow: $isManualFlow, error: $error)';
}


}

/// @nodoc
abstract mixin class _$PlanTripStateCopyWith<$Res> implements $PlanTripStateCopyWith<$Res> {
  factory _$PlanTripStateCopyWith(_PlanTripState value, $Res Function(_PlanTripState) _then) = __$PlanTripStateCopyWithImpl;
@override @useResult
$Res call({
 int currentStep, DateMode dateMode, DateTime? startDate, DateTime? endDate, int? preferredMonth, int? preferredYear, DurationPreset? flexibleDuration, int nbAdults, int nbChildren, int nbBabies, BudgetPreset? budgetPreset, String? originCity, List<LocationResult> originSearchResults, List<LocationResult> searchResults, bool isSearching, LocationResult? selectedManualDestination, List<AiDestination> aiSuggestions, bool isLoadingAiSuggestions, AiDestination? selectedAiDestination, Map<String, StepStatus> generationSteps, double generationProgress, String? generationMessage, TripPlan? generatedPlan, String? generationError, bool isCreating, String? createdTripId, bool isManualFlow, AppError? error
});


@override $LocationResultCopyWith<$Res>? get selectedManualDestination;@override $AiDestinationCopyWith<$Res>? get selectedAiDestination;@override $TripPlanCopyWith<$Res>? get generatedPlan;

}
/// @nodoc
class __$PlanTripStateCopyWithImpl<$Res>
    implements _$PlanTripStateCopyWith<$Res> {
  __$PlanTripStateCopyWithImpl(this._self, this._then);

  final _PlanTripState _self;
  final $Res Function(_PlanTripState) _then;

/// Create a copy of PlanTripState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? currentStep = null,Object? dateMode = null,Object? startDate = freezed,Object? endDate = freezed,Object? preferredMonth = freezed,Object? preferredYear = freezed,Object? flexibleDuration = freezed,Object? nbAdults = null,Object? nbChildren = null,Object? nbBabies = null,Object? budgetPreset = freezed,Object? originCity = freezed,Object? originSearchResults = null,Object? searchResults = null,Object? isSearching = null,Object? selectedManualDestination = freezed,Object? aiSuggestions = null,Object? isLoadingAiSuggestions = null,Object? selectedAiDestination = freezed,Object? generationSteps = null,Object? generationProgress = null,Object? generationMessage = freezed,Object? generatedPlan = freezed,Object? generationError = freezed,Object? isCreating = null,Object? createdTripId = freezed,Object? isManualFlow = null,Object? error = freezed,}) {
  return _then(_PlanTripState(
currentStep: null == currentStep ? _self.currentStep : currentStep // ignore: cast_nullable_to_non_nullable
as int,dateMode: null == dateMode ? _self.dateMode : dateMode // ignore: cast_nullable_to_non_nullable
as DateMode,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,preferredMonth: freezed == preferredMonth ? _self.preferredMonth : preferredMonth // ignore: cast_nullable_to_non_nullable
as int?,preferredYear: freezed == preferredYear ? _self.preferredYear : preferredYear // ignore: cast_nullable_to_non_nullable
as int?,flexibleDuration: freezed == flexibleDuration ? _self.flexibleDuration : flexibleDuration // ignore: cast_nullable_to_non_nullable
as DurationPreset?,nbAdults: null == nbAdults ? _self.nbAdults : nbAdults // ignore: cast_nullable_to_non_nullable
as int,nbChildren: null == nbChildren ? _self.nbChildren : nbChildren // ignore: cast_nullable_to_non_nullable
as int,nbBabies: null == nbBabies ? _self.nbBabies : nbBabies // ignore: cast_nullable_to_non_nullable
as int,budgetPreset: freezed == budgetPreset ? _self.budgetPreset : budgetPreset // ignore: cast_nullable_to_non_nullable
as BudgetPreset?,originCity: freezed == originCity ? _self.originCity : originCity // ignore: cast_nullable_to_non_nullable
as String?,originSearchResults: null == originSearchResults ? _self._originSearchResults : originSearchResults // ignore: cast_nullable_to_non_nullable
as List<LocationResult>,searchResults: null == searchResults ? _self._searchResults : searchResults // ignore: cast_nullable_to_non_nullable
as List<LocationResult>,isSearching: null == isSearching ? _self.isSearching : isSearching // ignore: cast_nullable_to_non_nullable
as bool,selectedManualDestination: freezed == selectedManualDestination ? _self.selectedManualDestination : selectedManualDestination // ignore: cast_nullable_to_non_nullable
as LocationResult?,aiSuggestions: null == aiSuggestions ? _self._aiSuggestions : aiSuggestions // ignore: cast_nullable_to_non_nullable
as List<AiDestination>,isLoadingAiSuggestions: null == isLoadingAiSuggestions ? _self.isLoadingAiSuggestions : isLoadingAiSuggestions // ignore: cast_nullable_to_non_nullable
as bool,selectedAiDestination: freezed == selectedAiDestination ? _self.selectedAiDestination : selectedAiDestination // ignore: cast_nullable_to_non_nullable
as AiDestination?,generationSteps: null == generationSteps ? _self._generationSteps : generationSteps // ignore: cast_nullable_to_non_nullable
as Map<String, StepStatus>,generationProgress: null == generationProgress ? _self.generationProgress : generationProgress // ignore: cast_nullable_to_non_nullable
as double,generationMessage: freezed == generationMessage ? _self.generationMessage : generationMessage // ignore: cast_nullable_to_non_nullable
as String?,generatedPlan: freezed == generatedPlan ? _self.generatedPlan : generatedPlan // ignore: cast_nullable_to_non_nullable
as TripPlan?,generationError: freezed == generationError ? _self.generationError : generationError // ignore: cast_nullable_to_non_nullable
as String?,isCreating: null == isCreating ? _self.isCreating : isCreating // ignore: cast_nullable_to_non_nullable
as bool,createdTripId: freezed == createdTripId ? _self.createdTripId : createdTripId // ignore: cast_nullable_to_non_nullable
as String?,isManualFlow: null == isManualFlow ? _self.isManualFlow : isManualFlow // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as AppError?,
  ));
}

/// Create a copy of PlanTripState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LocationResultCopyWith<$Res>? get selectedManualDestination {
    if (_self.selectedManualDestination == null) {
    return null;
  }

  return $LocationResultCopyWith<$Res>(_self.selectedManualDestination!, (value) {
    return _then(_self.copyWith(selectedManualDestination: value));
  });
}/// Create a copy of PlanTripState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AiDestinationCopyWith<$Res>? get selectedAiDestination {
    if (_self.selectedAiDestination == null) {
    return null;
  }

  return $AiDestinationCopyWith<$Res>(_self.selectedAiDestination!, (value) {
    return _then(_self.copyWith(selectedAiDestination: value));
  });
}/// Create a copy of PlanTripState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TripPlanCopyWith<$Res>? get generatedPlan {
    if (_self.generatedPlan == null) {
    return null;
  }

  return $TripPlanCopyWith<$Res>(_self.generatedPlan!, (value) {
    return _then(_self.copyWith(generatedPlan: value));
  });
}
}

// dart format on
