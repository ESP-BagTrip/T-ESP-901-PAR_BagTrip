import 'package:bagtrip/create_trip_ai/models/ai_trip_proposal.dart';
import 'package:bagtrip/create_trip_ai/models/trip_summary.dart';
import 'package:bagtrip/service/auth_service.dart';
import 'package:bagtrip/service/personalization_storage.dart';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'create_trip_ai_event.dart';
part 'create_trip_ai_state.dart';

List<AiTripProposal> _mockProposals() => [
  const AiTripProposal(
    id: '1',
    destination: 'Paris',
    destinationCountry: 'France',
    durationDays: 5,
    priceEur: 1500,
    description:
        'Découverte de la capitale : culture, gastronomie et monuments.',
  ),
  const AiTripProposal(
    id: '2',
    destination: 'Lyon',
    destinationCountry: 'France',
    durationDays: 3,
    priceEur: 800,
    description: 'Gastronomie et vieux Lyon.',
  ),
  const AiTripProposal(
    id: '3',
    destination: 'Bordeaux',
    destinationCountry: 'France',
    durationDays: 4,
    priceEur: 1100,
    description: 'Vignobles et patrimoine.',
  ),
  const AiTripProposal(
    id: '4',
    destination: 'Nice',
    destinationCountry: 'France',
    durationDays: 5,
    priceEur: 1200,
    description: 'Côte d\'Azur, mer et montagne.',
  ),
];

TripSummary _mockSummaryFor(AiTripProposal p) => TripSummary(
  destination: p.destination,
  destinationCountry: p.destinationCountry,
  durationDays: p.durationDays,
  budgetEur: p.priceEur,
  highlights: const [
    'Visite de la Tour Eiffel',
    'Dégustation de cuisine française',
    'Promenade au Louvre',
    'Croisière sur la Seine',
  ],
  accommodation: 'Hôtel 4 étoiles dans le Marais',
  dayByDayProgram: const [
    'Arrivée et découverte du quartier',
    'Musées et monuments',
    'Gastronomie et shopping',
    'Versailles',
    'Dernières visites et départ',
  ],
  essentialItems: const [
    'Crème solaire',
    'Anti-moustique',
    'Adaptateur de voyage',
    'Trousse de premiers secours',
  ],
);

class CreateTripAiBloc extends Bloc<CreateTripAiEvent, CreateTripAiState> {
  CreateTripAiBloc({
    AuthService? authService,
    PersonalizationStorage? personalizationStorage,
  }) : _authService = authService ?? AuthService(),
       _storage = personalizationStorage ?? PersonalizationStorage(),
       super(CreateTripAiInitial()) {
    on<CreateTripAiLoadRecap>(_onLoadRecap);
    on<CreateTripAiSetDepartureDate>(_onSetDepartureDate);
    on<CreateTripAiSetReturnDate>(_onSetReturnDate);
    on<CreateTripAiLaunchSearch>(_onLaunchSearch);
    on<CreateTripAiSelectProposal>(_onSelectProposal);
    on<CreateTripAiRegenerate>(_onRegenerate);
  }

  final AuthService _authService;
  final PersonalizationStorage _storage;

  Future<void> _onLoadRecap(
    CreateTripAiLoadRecap event,
    Emitter<CreateTripAiState> emit,
  ) async {
    emit(CreateTripAiRecapLoading());
    try {
      final user = await _authService.getCurrentUser();
      final userId = user?.id ?? '';
      String travelTypes = '';
      String? travelStyle;
      String? budget;
      String? companions;
      if (userId.isNotEmpty) {
        travelTypes = await _storage.getTravelTypes(userId);
        travelStyle = await _storage.getTravelStyle(userId);
        final b = await _storage.getBudget(userId);
        travelStyle = travelStyle.isEmpty ? null : travelStyle;
        budget = b.isEmpty ? null : b;
        companions = await _storage.getCompanions(userId);
        companions = companions.isEmpty ? null : companions;
      }
      emit(
        CreateTripAiRecapLoaded(
          travelTypes: travelTypes.isEmpty ? 'Non renseigné' : travelTypes,
          travelStyle: travelStyle,
          budget: budget,
          companions: companions,
        ),
      );
    } catch (_) {
      emit(
        CreateTripAiRecapLoaded(
          travelTypes: 'Non renseigné',
          travelStyle: null,
          budget: null,
          companions: null,
        ),
      );
    }
  }

  void _onSetDepartureDate(
    CreateTripAiSetDepartureDate event,
    Emitter<CreateTripAiState> emit,
  ) {
    final s = state;
    if (s is CreateTripAiRecapLoaded) {
      emit(s.copyWith(departureDate: event.date));
    }
  }

  void _onSetReturnDate(
    CreateTripAiSetReturnDate event,
    Emitter<CreateTripAiState> emit,
  ) {
    final s = state;
    if (s is CreateTripAiRecapLoaded) {
      emit(s.copyWith(returnDate: event.date));
    }
  }

  void _onLaunchSearch(
    CreateTripAiLaunchSearch event,
    Emitter<CreateTripAiState> emit,
  ) {
    emit(CreateTripAiResultsLoaded(_mockProposals()));
  }

  void _onSelectProposal(
    CreateTripAiSelectProposal event,
    Emitter<CreateTripAiState> emit,
  ) {
    emit(CreateTripAiSummaryLoaded(_mockSummaryFor(event.proposal)));
  }

  void _onRegenerate(
    CreateTripAiRegenerate event,
    Emitter<CreateTripAiState> emit,
  ) {
    emit(CreateTripAiResultsLoaded(_mockProposals()));
  }
}
