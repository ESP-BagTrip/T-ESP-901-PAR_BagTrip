import 'package:bagtrip/service/api_client.dart';
import 'package:bagtrip/service/storage_service.dart';
import 'package:bagtrip/service/personalization_storage.dart';
import 'package:bagtrip/service/location_service.dart';
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockStorageService extends Mock implements StorageService {}

class MockPersonalizationStorage extends Mock
    implements PersonalizationStorage {}

class MockLocationService extends Mock implements LocationService {}
