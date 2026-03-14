import 'package:bagtrip/models/accommodation.dart';
import 'package:bagtrip/models/baggage_item.dart';
import 'package:bagtrip/models/traveler.dart';
import 'package:bagtrip/models/traveler_profile.dart';
import 'package:bagtrip/models/notification.dart';
import 'package:bagtrip/models/feedback.dart';
import 'package:bagtrip/models/trip_share.dart';
import 'package:bagtrip/models/booking_response.dart';
import 'package:bagtrip/models/trip_grouped.dart';
import 'package:bagtrip/models/trip_home.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Accommodation
  // ---------------------------------------------------------------------------
  group('Accommodation', () {
    group('fromJson', () {
      test('parses all fields correctly', () {
        final json = <String, dynamic>{
          'id': 'acc-1',
          'tripId': 'trip-1',
          'name': 'Hotel Le Marais',
          'address': '12 Rue de Rivoli, Paris',
          'checkIn': '2024-06-01T14:00:00.000',
          'checkOut': '2024-06-05T11:00:00.000',
          'pricePerNight': 150.0,
          'currency': 'EUR',
          'bookingReference': 'BK-123456',
          'notes': 'Near metro station',
          'createdAt': '2024-01-15T10:30:00.000',
          'updatedAt': '2024-02-20T14:00:00.000',
        };

        final acc = Accommodation.fromJson(json);

        expect(acc.id, 'acc-1');
        expect(acc.tripId, 'trip-1');
        expect(acc.name, 'Hotel Le Marais');
        expect(acc.address, '12 Rue de Rivoli, Paris');
        expect(acc.checkIn, DateTime.parse('2024-06-01T14:00:00.000'));
        expect(acc.checkOut, DateTime.parse('2024-06-05T11:00:00.000'));
        expect(acc.pricePerNight, 150.0);
        expect(acc.currency, 'EUR');
        expect(acc.bookingReference, 'BK-123456');
        expect(acc.notes, 'Near metro station');
        expect(acc.createdAt, DateTime.parse('2024-01-15T10:30:00.000'));
        expect(acc.updatedAt, DateTime.parse('2024-02-20T14:00:00.000'));
      });

      test('parses with only required fields', () {
        final json = <String, dynamic>{
          'id': 'acc-2',
          'tripId': 'trip-2',
          'name': 'Airbnb Studio',
        };

        final acc = Accommodation.fromJson(json);

        expect(acc.id, 'acc-2');
        expect(acc.tripId, 'trip-2');
        expect(acc.name, 'Airbnb Studio');
        expect(acc.address, isNull);
        expect(acc.checkIn, isNull);
        expect(acc.checkOut, isNull);
        expect(acc.pricePerNight, isNull);
        expect(acc.currency, isNull);
        expect(acc.bookingReference, isNull);
        expect(acc.notes, isNull);
        expect(acc.createdAt, isNull);
        expect(acc.updatedAt, isNull);
      });
    });

    group('toJson', () {
      test('roundtrip produces equal object', () {
        final acc = Accommodation(
          id: 'acc-rt',
          tripId: 'trip-rt',
          name: 'Grand Hotel',
          address: '1 Main St',
          checkIn: DateTime.parse('2024-06-01T14:00:00.000'),
          checkOut: DateTime.parse('2024-06-05T11:00:00.000'),
          pricePerNight: 200.0,
          currency: 'USD',
          bookingReference: 'REF-789',
          notes: 'Pool access',
          createdAt: DateTime.parse('2024-01-01T00:00:00.000'),
          updatedAt: DateTime.parse('2024-03-01T00:00:00.000'),
        );

        final json = acc.toJson();
        final restored = Accommodation.fromJson(json);

        expect(restored, acc);
      });
    });

    group('equality', () {
      test('two accommodations with same fields are equal', () {
        final a1 = const Accommodation(id: 'a1', tripId: 't1', name: 'Hotel A');
        final a2 = const Accommodation(id: 'a1', tripId: 't1', name: 'Hotel A');
        expect(a1, a2);
      });

      test('two accommodations with different fields are not equal', () {
        final a1 = const Accommodation(id: 'a1', tripId: 't1', name: 'Hotel A');
        final a2 = const Accommodation(id: 'a2', tripId: 't1', name: 'Hotel A');
        expect(a1, isNot(a2));
      });
    });

    group('copyWith', () {
      test('copies with changed fields', () {
        final acc = const Accommodation(
          id: 'a1',
          tripId: 't1',
          name: 'Old Name',
        );
        final updated = acc.copyWith(name: 'New Name', currency: 'EUR');

        expect(updated.id, 'a1');
        expect(updated.name, 'New Name');
        expect(updated.currency, 'EUR');
      });
    });
  });

  // ---------------------------------------------------------------------------
  // BaggageItem
  // ---------------------------------------------------------------------------
  group('BaggageItem', () {
    group('fromJson', () {
      test('parses all fields correctly', () {
        final json = <String, dynamic>{
          'id': 'bag-1',
          'tripId': 'trip-1',
          'name': 'Passport',
          'quantity': 1,
          'isPacked': true,
          'category': 'documents',
          'notes': 'Check expiry',
          'createdAt': '2024-01-15T10:30:00.000',
          'updatedAt': '2024-02-20T14:00:00.000',
        };

        final item = BaggageItem.fromJson(json);

        expect(item.id, 'bag-1');
        expect(item.tripId, 'trip-1');
        expect(item.name, 'Passport');
        expect(item.quantity, 1);
        expect(item.isPacked, true);
        expect(item.category, 'documents');
        expect(item.notes, 'Check expiry');
        expect(item.createdAt, DateTime.parse('2024-01-15T10:30:00.000'));
        expect(item.updatedAt, DateTime.parse('2024-02-20T14:00:00.000'));
      });

      test('parses with only required fields and applies defaults', () {
        final json = <String, dynamic>{
          'id': 'bag-2',
          'tripId': 'trip-2',
          'name': 'Sunglasses',
        };

        final item = BaggageItem.fromJson(json);

        expect(item.id, 'bag-2');
        expect(item.tripId, 'trip-2');
        expect(item.name, 'Sunglasses');
        expect(item.quantity, isNull);
        expect(item.isPacked, false);
        expect(item.category, isNull);
        expect(item.notes, isNull);
        expect(item.createdAt, isNull);
        expect(item.updatedAt, isNull);
      });
    });

    group('toJson', () {
      test('roundtrip produces equal object', () {
        final item = BaggageItem(
          id: 'bag-rt',
          tripId: 'trip-rt',
          name: 'Charger',
          quantity: 2,
          isPacked: true,
          category: 'electronics',
          notes: 'USB-C',
          createdAt: DateTime.parse('2024-01-01T00:00:00.000'),
          updatedAt: DateTime.parse('2024-03-01T00:00:00.000'),
        );

        final json = item.toJson();
        final restored = BaggageItem.fromJson(json);

        expect(restored, item);
      });
    });

    group('equality', () {
      test('two items with same fields are equal', () {
        final b1 = const BaggageItem(id: 'b1', tripId: 't1', name: 'Shirt');
        final b2 = const BaggageItem(id: 'b1', tripId: 't1', name: 'Shirt');
        expect(b1, b2);
      });

      test('two items with different fields are not equal', () {
        final b1 = const BaggageItem(id: 'b1', tripId: 't1', name: 'Shirt');
        final b2 = const BaggageItem(id: 'b2', tripId: 't1', name: 'Shirt');
        expect(b1, isNot(b2));
      });
    });

    group('copyWith', () {
      test('copies with changed fields', () {
        final item = const BaggageItem(id: 'b1', tripId: 't1', name: 'Old');
        final updated = item.copyWith(name: 'New', isPacked: true);

        expect(updated.id, 'b1');
        expect(updated.name, 'New');
        expect(updated.isPacked, true);
      });
    });
  });

  // ---------------------------------------------------------------------------
  // Traveler
  // ---------------------------------------------------------------------------
  group('Traveler', () {
    group('fromJson', () {
      test('parses all fields correctly', () {
        final json = <String, dynamic>{
          'id': 'trav-1',
          'tripId': 'trip-1',
          'amadeusTravelerRef': 'AMX-001',
          'travelerType': 'CHILD',
          'firstName': 'Alice',
          'lastName': 'Smith',
          'dateOfBirth': '2015-03-20T00:00:00.000',
          'gender': 'F',
          'documents': [
            {'type': 'PASSPORT', 'number': 'AB123456'},
          ],
          'contacts': {'email': 'parent@example.com', 'phone': '+33600000000'},
          'createdAt': '2024-01-15T10:30:00.000',
          'updatedAt': '2024-02-20T14:00:00.000',
        };

        final traveler = Traveler.fromJson(json);

        expect(traveler.id, 'trav-1');
        expect(traveler.tripId, 'trip-1');
        expect(traveler.amadeusTravelerRef, 'AMX-001');
        expect(traveler.travelerType, 'CHILD');
        expect(traveler.firstName, 'Alice');
        expect(traveler.lastName, 'Smith');
        expect(traveler.dateOfBirth, DateTime.parse('2015-03-20T00:00:00.000'));
        expect(traveler.gender, 'F');
        expect(traveler.documents, [
          {'type': 'PASSPORT', 'number': 'AB123456'},
        ]);
        expect(traveler.contacts, {
          'email': 'parent@example.com',
          'phone': '+33600000000',
        });
        expect(traveler.createdAt, DateTime.parse('2024-01-15T10:30:00.000'));
        expect(traveler.updatedAt, DateTime.parse('2024-02-20T14:00:00.000'));
      });

      test('parses with only required fields and applies defaults', () {
        final json = <String, dynamic>{
          'id': 'trav-2',
          'tripId': 'trip-2',
          'firstName': 'Bob',
          'lastName': 'Jones',
        };

        final traveler = Traveler.fromJson(json);

        expect(traveler.id, 'trav-2');
        expect(traveler.tripId, 'trip-2');
        expect(traveler.firstName, 'Bob');
        expect(traveler.lastName, 'Jones');
        expect(traveler.amadeusTravelerRef, isNull);
        expect(traveler.travelerType, 'ADULT');
        expect(traveler.dateOfBirth, isNull);
        expect(traveler.gender, isNull);
        expect(traveler.documents, isNull);
        expect(traveler.contacts, isNull);
        expect(traveler.createdAt, isNull);
        expect(traveler.updatedAt, isNull);
      });
    });

    group('toJson', () {
      test('roundtrip produces equal object', () {
        final traveler = Traveler(
          id: 'trav-rt',
          tripId: 'trip-rt',
          amadeusTravelerRef: 'AMX-002',
          firstName: 'Carol',
          lastName: 'Brown',
          dateOfBirth: DateTime.parse('1990-05-10T00:00:00.000'),
          gender: 'F',
          documents: [
            {'type': 'ID_CARD', 'number': 'XY987654'},
          ],
          contacts: {'email': 'carol@test.com'},
          createdAt: DateTime.parse('2024-01-01T00:00:00.000'),
          updatedAt: DateTime.parse('2024-03-01T00:00:00.000'),
        );

        final json = traveler.toJson();
        final restored = Traveler.fromJson(json);

        expect(restored, traveler);
      });
    });

    group('equality', () {
      test('two travelers with same fields are equal', () {
        final t1 = const Traveler(
          id: 't1',
          tripId: 'tr1',
          firstName: 'A',
          lastName: 'B',
        );
        final t2 = const Traveler(
          id: 't1',
          tripId: 'tr1',
          firstName: 'A',
          lastName: 'B',
        );
        expect(t1, t2);
      });

      test('two travelers with different fields are not equal', () {
        final t1 = const Traveler(
          id: 't1',
          tripId: 'tr1',
          firstName: 'A',
          lastName: 'B',
        );
        final t2 = const Traveler(
          id: 't2',
          tripId: 'tr1',
          firstName: 'A',
          lastName: 'B',
        );
        expect(t1, isNot(t2));
      });
    });

    group('copyWith', () {
      test('copies with changed fields', () {
        final traveler = const Traveler(
          id: 't1',
          tripId: 'tr1',
          firstName: 'Old',
          lastName: 'Name',
        );
        final updated = traveler.copyWith(
          firstName: 'New',
          travelerType: 'CHILD',
        );

        expect(updated.id, 't1');
        expect(updated.firstName, 'New');
        expect(updated.lastName, 'Name');
        expect(updated.travelerType, 'CHILD');
      });
    });
  });

  // ---------------------------------------------------------------------------
  // TravelerProfile
  // ---------------------------------------------------------------------------
  group('TravelerProfile', () {
    group('fromJson', () {
      test('parses all fields correctly', () {
        final json = <String, dynamic>{
          'id': 'profile-1',
          'travelTypes': ['beach', 'city'],
          'travelStyle': 'luxury',
          'budget': 'high',
          'companions': 'couple',
          'isCompleted': true,
          'createdAt': '2024-01-15T10:30:00.000',
          'updatedAt': '2024-02-20T14:00:00.000',
        };

        final profile = TravelerProfile.fromJson(json);

        expect(profile.id, 'profile-1');
        expect(profile.travelTypes, ['beach', 'city']);
        expect(profile.travelStyle, 'luxury');
        expect(profile.budget, 'high');
        expect(profile.companions, 'couple');
        expect(profile.isCompleted, true);
        expect(profile.createdAt, DateTime.parse('2024-01-15T10:30:00.000'));
        expect(profile.updatedAt, DateTime.parse('2024-02-20T14:00:00.000'));
      });

      test('parses with only required fields and applies defaults', () {
        final json = <String, dynamic>{'id': 'profile-2'};

        final profile = TravelerProfile.fromJson(json);

        expect(profile.id, 'profile-2');
        expect(profile.travelTypes, <String>[]);
        expect(profile.travelStyle, isNull);
        expect(profile.budget, isNull);
        expect(profile.companions, isNull);
        expect(profile.isCompleted, false);
        expect(profile.createdAt, isNull);
        expect(profile.updatedAt, isNull);
      });
    });

    group('toJson', () {
      test('roundtrip produces equal object', () {
        final profile = TravelerProfile(
          id: 'profile-rt',
          travelTypes: ['adventure', 'cultural'],
          travelStyle: 'backpacker',
          budget: 'low',
          companions: 'solo',
          isCompleted: true,
          createdAt: DateTime.parse('2024-01-01T00:00:00.000'),
          updatedAt: DateTime.parse('2024-03-01T00:00:00.000'),
        );

        final json = profile.toJson();
        final restored = TravelerProfile.fromJson(json);

        expect(restored, profile);
      });
    });

    group('equality', () {
      test('two profiles with same fields are equal', () {
        final p1 = const TravelerProfile(id: 'p1', travelTypes: ['beach']);
        final p2 = const TravelerProfile(id: 'p1', travelTypes: ['beach']);
        expect(p1, p2);
      });
    });

    group('copyWith', () {
      test('copies with changed fields', () {
        final profile = const TravelerProfile(id: 'p1');
        final updated = profile.copyWith(
          isCompleted: true,
          travelTypes: ['adventure'],
        );

        expect(updated.id, 'p1');
        expect(updated.isCompleted, true);
        expect(updated.travelTypes, ['adventure']);
      });
    });
  });

  // ---------------------------------------------------------------------------
  // ProfileCompletion
  // ---------------------------------------------------------------------------
  group('ProfileCompletion', () {
    group('fromJson', () {
      test('parses all fields correctly', () {
        final json = <String, dynamic>{
          'isCompleted': true,
          'missingFields': ['phone', 'travelStyle'],
        };

        final completion = ProfileCompletion.fromJson(json);

        expect(completion.isCompleted, true);
        expect(completion.missingFields, ['phone', 'travelStyle']);
      });

      test('applies defaults when fields are missing', () {
        final json = <String, dynamic>{};

        final completion = ProfileCompletion.fromJson(json);

        expect(completion.isCompleted, false);
        expect(completion.missingFields, <String>[]);
      });
    });

    group('toJson', () {
      test('roundtrip produces equal object', () {
        final completion = const ProfileCompletion(
          isCompleted: true,
          missingFields: ['budget'],
        );

        final json = completion.toJson();
        final restored = ProfileCompletion.fromJson(json);

        expect(restored, completion);
      });
    });

    group('equality', () {
      test('two completions with same fields are equal', () {
        final c1 = const ProfileCompletion(missingFields: ['a']);
        final c2 = const ProfileCompletion(missingFields: ['a']);
        expect(c1, c2);
      });

      test('two completions with different fields are not equal', () {
        final c1 = const ProfileCompletion(isCompleted: true);
        final c2 = const ProfileCompletion();
        expect(c1, isNot(c2));
      });
    });

    group('copyWith', () {
      test('copies with changed fields', () {
        const completion = ProfileCompletion();
        final updated = completion.copyWith(
          isCompleted: true,
          missingFields: ['phone'],
        );

        expect(updated.isCompleted, true);
        expect(updated.missingFields, ['phone']);
      });
    });
  });

  // ---------------------------------------------------------------------------
  // AppNotification
  // ---------------------------------------------------------------------------
  group('AppNotification', () {
    group('fromJson', () {
      test('parses all fields correctly', () {
        final json = <String, dynamic>{
          'id': 'notif-1',
          'type': 'trip_update',
          'title': 'Trip Updated',
          'body': 'Your trip to Paris has been updated',
          'data': {'tripId': 'trip-1', 'action': 'status_change'},
          'isRead': true,
          'tripId': 'trip-1',
          'sentAt': '2024-01-15T10:30:00.000',
          'createdAt': '2024-01-15T10:30:00.000',
        };

        final notif = AppNotification.fromJson(json);

        expect(notif.id, 'notif-1');
        expect(notif.type, 'trip_update');
        expect(notif.title, 'Trip Updated');
        expect(notif.body, 'Your trip to Paris has been updated');
        expect(notif.data, {'tripId': 'trip-1', 'action': 'status_change'});
        expect(notif.isRead, true);
        expect(notif.tripId, 'trip-1');
        expect(notif.sentAt, DateTime.parse('2024-01-15T10:30:00.000'));
        expect(notif.createdAt, DateTime.parse('2024-01-15T10:30:00.000'));
      });

      test('parses with only required fields and applies defaults', () {
        final json = <String, dynamic>{
          'id': 'notif-2',
          'type': 'info',
          'title': 'Welcome',
          'body': 'Welcome to BagTrip!',
        };

        final notif = AppNotification.fromJson(json);

        expect(notif.id, 'notif-2');
        expect(notif.type, 'info');
        expect(notif.title, 'Welcome');
        expect(notif.body, 'Welcome to BagTrip!');
        expect(notif.data, isNull);
        expect(notif.isRead, false);
        expect(notif.tripId, isNull);
        expect(notif.sentAt, isNull);
        expect(notif.createdAt, isNull);
      });
    });

    group('toJson', () {
      test('roundtrip produces equal object', () {
        final notif = AppNotification(
          id: 'notif-rt',
          type: 'reminder',
          title: 'Pack your bags',
          body: 'Your trip starts tomorrow',
          data: {'countdown': 1},
          tripId: 'trip-rt',
          sentAt: DateTime.parse('2024-06-01T08:00:00.000'),
          createdAt: DateTime.parse('2024-06-01T08:00:00.000'),
        );

        final json = notif.toJson();
        final restored = AppNotification.fromJson(json);

        expect(restored, notif);
      });
    });

    group('equality', () {
      test('two notifications with same fields are equal', () {
        final n1 = const AppNotification(
          id: 'n1',
          type: 'info',
          title: 'Hi',
          body: 'Hello',
        );
        final n2 = const AppNotification(
          id: 'n1',
          type: 'info',
          title: 'Hi',
          body: 'Hello',
        );
        expect(n1, n2);
      });

      test('two notifications with different fields are not equal', () {
        final n1 = const AppNotification(
          id: 'n1',
          type: 'info',
          title: 'Hi',
          body: 'Hello',
        );
        final n2 = const AppNotification(
          id: 'n2',
          type: 'info',
          title: 'Hi',
          body: 'Hello',
        );
        expect(n1, isNot(n2));
      });
    });

    group('copyWith', () {
      test('copies with changed fields', () {
        final notif = const AppNotification(
          id: 'n1',
          type: 'info',
          title: 'Old',
          body: 'Old body',
        );
        final updated = notif.copyWith(title: 'New', isRead: true);

        expect(updated.id, 'n1');
        expect(updated.title, 'New');
        expect(updated.isRead, true);
        expect(updated.body, 'Old body');
      });
    });
  });

  // ---------------------------------------------------------------------------
  // TripFeedback
  // ---------------------------------------------------------------------------
  group('TripFeedback', () {
    group('fromJson', () {
      test('parses all fields correctly', () {
        final json = <String, dynamic>{
          'id': 'fb-1',
          'tripId': 'trip-1',
          'userId': 'user-1',
          'overallRating': 5,
          'highlights': 'Amazing food and culture',
          'lowlights': 'Rainy weather',
          'wouldRecommend': true,
          'createdAt': '2024-01-15T10:30:00.000',
        };

        final feedback = TripFeedback.fromJson(json);

        expect(feedback.id, 'fb-1');
        expect(feedback.tripId, 'trip-1');
        expect(feedback.userId, 'user-1');
        expect(feedback.overallRating, 5);
        expect(feedback.highlights, 'Amazing food and culture');
        expect(feedback.lowlights, 'Rainy weather');
        expect(feedback.wouldRecommend, true);
        expect(feedback.createdAt, DateTime.parse('2024-01-15T10:30:00.000'));
      });

      test('parses with only required fields and applies defaults', () {
        final json = <String, dynamic>{
          'id': 'fb-2',
          'tripId': 'trip-2',
          'userId': 'user-2',
          'overallRating': 3,
        };

        final feedback = TripFeedback.fromJson(json);

        expect(feedback.id, 'fb-2');
        expect(feedback.tripId, 'trip-2');
        expect(feedback.userId, 'user-2');
        expect(feedback.overallRating, 3);
        expect(feedback.highlights, isNull);
        expect(feedback.lowlights, isNull);
        expect(feedback.wouldRecommend, false);
        expect(feedback.createdAt, isNull);
      });
    });

    group('toJson', () {
      test('roundtrip produces equal object', () {
        final feedback = TripFeedback(
          id: 'fb-rt',
          tripId: 'trip-rt',
          userId: 'user-rt',
          overallRating: 4,
          highlights: 'Great views',
          lowlights: 'Expensive',
          wouldRecommend: true,
          createdAt: DateTime.parse('2024-07-01T00:00:00.000'),
        );

        final json = feedback.toJson();
        final restored = TripFeedback.fromJson(json);

        expect(restored, feedback);
      });
    });

    group('equality', () {
      test('two feedbacks with same fields are equal', () {
        final f1 = const TripFeedback(
          id: 'f1',
          tripId: 't1',
          userId: 'u1',
          overallRating: 4,
        );
        final f2 = const TripFeedback(
          id: 'f1',
          tripId: 't1',
          userId: 'u1',
          overallRating: 4,
        );
        expect(f1, f2);
      });

      test('two feedbacks with different fields are not equal', () {
        final f1 = const TripFeedback(
          id: 'f1',
          tripId: 't1',
          userId: 'u1',
          overallRating: 4,
        );
        final f2 = const TripFeedback(
          id: 'f2',
          tripId: 't1',
          userId: 'u1',
          overallRating: 4,
        );
        expect(f1, isNot(f2));
      });
    });

    group('copyWith', () {
      test('copies with changed fields', () {
        final feedback = const TripFeedback(
          id: 'f1',
          tripId: 't1',
          userId: 'u1',
          overallRating: 3,
        );
        final updated = feedback.copyWith(
          overallRating: 5,
          wouldRecommend: true,
          highlights: 'Wonderful',
        );

        expect(updated.id, 'f1');
        expect(updated.overallRating, 5);
        expect(updated.wouldRecommend, true);
        expect(updated.highlights, 'Wonderful');
      });
    });
  });

  // ---------------------------------------------------------------------------
  // TripShare
  // ---------------------------------------------------------------------------
  group('TripShare', () {
    group('fromJson', () {
      test('parses all fields correctly', () {
        final json = <String, dynamic>{
          'id': 'share-1',
          'tripId': 'trip-1',
          'userId': 'user-2',
          'role': 'EDITOR',
          'invitedAt': '2024-01-15T10:30:00.000',
          'userEmail': 'bob@example.com',
          'userFullName': 'Bob Jones',
        };

        final share = TripShare.fromJson(json);

        expect(share.id, 'share-1');
        expect(share.tripId, 'trip-1');
        expect(share.userId, 'user-2');
        expect(share.role, 'EDITOR');
        expect(share.invitedAt, DateTime.parse('2024-01-15T10:30:00.000'));
        expect(share.userEmail, 'bob@example.com');
        expect(share.userFullName, 'Bob Jones');
      });

      test('parses with only required fields and applies defaults', () {
        final json = <String, dynamic>{
          'id': 'share-2',
          'tripId': 'trip-2',
          'userId': 'user-3',
          'userEmail': 'carol@example.com',
        };

        final share = TripShare.fromJson(json);

        expect(share.id, 'share-2');
        expect(share.tripId, 'trip-2');
        expect(share.userId, 'user-3');
        expect(share.role, 'VIEWER');
        expect(share.invitedAt, isNull);
        expect(share.userEmail, 'carol@example.com');
        expect(share.userFullName, isNull);
      });
    });

    group('toJson', () {
      test('roundtrip produces equal object', () {
        final share = TripShare(
          id: 'share-rt',
          tripId: 'trip-rt',
          userId: 'user-rt',
          role: 'EDITOR',
          invitedAt: DateTime.parse('2024-01-01T00:00:00.000'),
          userEmail: 'test@test.com',
          userFullName: 'Test User',
        );

        final json = share.toJson();
        final restored = TripShare.fromJson(json);

        expect(restored, share);
      });
    });

    group('equality', () {
      test('two shares with same fields are equal', () {
        final s1 = const TripShare(
          id: 's1',
          tripId: 't1',
          userId: 'u1',
          userEmail: 'a@b.com',
        );
        final s2 = const TripShare(
          id: 's1',
          tripId: 't1',
          userId: 'u1',
          userEmail: 'a@b.com',
        );
        expect(s1, s2);
      });

      test('two shares with different fields are not equal', () {
        final s1 = const TripShare(
          id: 's1',
          tripId: 't1',
          userId: 'u1',
          userEmail: 'a@b.com',
        );
        final s2 = const TripShare(
          id: 's2',
          tripId: 't1',
          userId: 'u1',
          userEmail: 'a@b.com',
        );
        expect(s1, isNot(s2));
      });
    });

    group('copyWith', () {
      test('copies with changed fields', () {
        final share = const TripShare(
          id: 's1',
          tripId: 't1',
          userId: 'u1',
          userEmail: 'a@b.com',
        );
        final updated = share.copyWith(role: 'EDITOR');

        expect(updated.id, 's1');
        expect(updated.role, 'EDITOR');
        expect(updated.userEmail, 'a@b.com');
      });
    });
  });

  // ---------------------------------------------------------------------------
  // BookingResponse
  // ---------------------------------------------------------------------------
  group('BookingResponse', () {
    group('fromJson', () {
      test('parses all fields correctly', () {
        final json = <String, dynamic>{
          'id': 'booking-1',
          'amadeusOrderId': 'AMX-ORD-001',
          'status': 'confirmed',
          'priceTotal': 1250.75,
          'currency': 'EUR',
          'createdAt': '2024-01-15T10:30:00.000',
        };

        final booking = BookingResponse.fromJson(json);

        expect(booking.id, 'booking-1');
        expect(booking.amadeusOrderId, 'AMX-ORD-001');
        expect(booking.status, 'confirmed');
        expect(booking.priceTotal, 1250.75);
        expect(booking.currency, 'EUR');
        expect(booking.createdAt, DateTime.parse('2024-01-15T10:30:00.000'));
      });

      test('parses with only required fields', () {
        final json = <String, dynamic>{
          'id': 'booking-2',
          'amadeusOrderId': 'AMX-ORD-002',
          'status': 'pending',
          'priceTotal': 500.0,
          'currency': 'USD',
        };

        final booking = BookingResponse.fromJson(json);

        expect(booking.id, 'booking-2');
        expect(booking.amadeusOrderId, 'AMX-ORD-002');
        expect(booking.status, 'pending');
        expect(booking.priceTotal, 500.0);
        expect(booking.currency, 'USD');
        expect(booking.createdAt, isNull);
      });
    });

    group('toJson', () {
      test('roundtrip produces equal object', () {
        final booking = BookingResponse(
          id: 'booking-rt',
          amadeusOrderId: 'AMX-RT',
          status: 'confirmed',
          priceTotal: 999.99,
          currency: 'GBP',
          createdAt: DateTime.parse('2024-01-01T00:00:00.000'),
        );

        final json = booking.toJson();
        final restored = BookingResponse.fromJson(json);

        expect(restored, booking);
      });
    });

    group('equality', () {
      test('two bookings with same fields are equal', () {
        final b1 = const BookingResponse(
          id: 'b1',
          amadeusOrderId: 'ord1',
          status: 'ok',
          priceTotal: 100.0,
          currency: 'EUR',
        );
        final b2 = const BookingResponse(
          id: 'b1',
          amadeusOrderId: 'ord1',
          status: 'ok',
          priceTotal: 100.0,
          currency: 'EUR',
        );
        expect(b1, b2);
      });

      test('two bookings with different fields are not equal', () {
        final b1 = const BookingResponse(
          id: 'b1',
          amadeusOrderId: 'ord1',
          status: 'ok',
          priceTotal: 100.0,
          currency: 'EUR',
        );
        final b2 = const BookingResponse(
          id: 'b2',
          amadeusOrderId: 'ord1',
          status: 'ok',
          priceTotal: 100.0,
          currency: 'EUR',
        );
        expect(b1, isNot(b2));
      });
    });

    group('copyWith', () {
      test('copies with changed fields', () {
        final booking = const BookingResponse(
          id: 'b1',
          amadeusOrderId: 'ord1',
          status: 'pending',
          priceTotal: 100.0,
          currency: 'EUR',
        );
        final updated = booking.copyWith(
          status: 'confirmed',
          priceTotal: 150.0,
        );

        expect(updated.id, 'b1');
        expect(updated.status, 'confirmed');
        expect(updated.priceTotal, 150.0);
        expect(updated.currency, 'EUR');
      });
    });
  });

  // ---------------------------------------------------------------------------
  // TripGrouped
  // ---------------------------------------------------------------------------
  group('TripGrouped', () {
    final sampleTrip1 = const Trip(
      id: 'trip-1',
      userId: 'user-1',
      status: TripStatus.ongoing,
    );
    final sampleTrip2 = const Trip(
      id: 'trip-2',
      userId: 'user-1',
      status: TripStatus.planned,
    );
    final sampleTrip3 = const Trip(
      id: 'trip-3',
      userId: 'user-1',
      status: TripStatus.completed,
    );

    group('fromJson', () {
      test('parses all fields correctly', () {
        final json = <String, dynamic>{
          'ongoing': [
            {'id': 'trip-1', 'userId': 'user-1', 'status': 'ongoing'},
          ],
          'planned': [
            {'id': 'trip-2', 'userId': 'user-1', 'status': 'planned'},
          ],
          'completed': [
            {'id': 'trip-3', 'userId': 'user-1', 'status': 'completed'},
          ],
        };

        final grouped = TripGrouped.fromJson(json);

        expect(grouped.ongoing.length, 1);
        expect(grouped.ongoing.first.id, 'trip-1');
        expect(grouped.planned.length, 1);
        expect(grouped.planned.first.id, 'trip-2');
        expect(grouped.completed.length, 1);
        expect(grouped.completed.first.id, 'trip-3');
      });

      test('applies defaults for empty JSON', () {
        final json = <String, dynamic>{};

        final grouped = TripGrouped.fromJson(json);

        expect(grouped.ongoing, <Trip>[]);
        expect(grouped.planned, <Trip>[]);
        expect(grouped.completed, <Trip>[]);
      });

      test('handles partial data', () {
        final json = <String, dynamic>{
          'ongoing': [
            {'id': 'trip-1', 'userId': 'user-1'},
          ],
        };

        final grouped = TripGrouped.fromJson(json);

        expect(grouped.ongoing.length, 1);
        expect(grouped.planned, <Trip>[]);
        expect(grouped.completed, <Trip>[]);
      });
    });

    group('toJson', () {
      test('roundtrip produces equal object', () {
        final grouped = TripGrouped(
          ongoing: [sampleTrip1],
          planned: [sampleTrip2],
          completed: [sampleTrip3],
        );

        final json = grouped.toJson();
        final restored = TripGrouped.fromJson(json);

        expect(restored, grouped);
      });
    });

    group('equality', () {
      test('two grouped with same trips are equal', () {
        final g1 = TripGrouped(ongoing: [sampleTrip1]);
        final g2 = TripGrouped(ongoing: [sampleTrip1]);
        expect(g1, g2);
      });

      test('two grouped with different trips are not equal', () {
        final g1 = TripGrouped(ongoing: [sampleTrip1]);
        final g2 = TripGrouped(ongoing: [sampleTrip2]);
        expect(g1, isNot(g2));
      });
    });

    group('copyWith', () {
      test('copies with changed fields', () {
        const grouped = TripGrouped();
        final updated = grouped.copyWith(
          ongoing: [sampleTrip1],
          planned: [sampleTrip2],
        );

        expect(updated.ongoing.length, 1);
        expect(updated.planned.length, 1);
        expect(updated.completed, <Trip>[]);
      });
    });
  });

  // ---------------------------------------------------------------------------
  // TripHomeStats
  // ---------------------------------------------------------------------------
  group('TripHomeStats', () {
    group('fromJson', () {
      test('parses all fields correctly', () {
        final json = <String, dynamic>{
          'baggageCount': 12,
          'totalExpenses': 1500.50,
          'nbTravelers': 3,
          'daysUntilTrip': 10,
          'tripDuration': 7,
        };

        final stats = TripHomeStats.fromJson(json);

        expect(stats.baggageCount, 12);
        expect(stats.totalExpenses, 1500.50);
        expect(stats.nbTravelers, 3);
        expect(stats.daysUntilTrip, 10);
        expect(stats.tripDuration, 7);
      });

      test('applies defaults for empty JSON', () {
        final json = <String, dynamic>{};

        final stats = TripHomeStats.fromJson(json);

        expect(stats.baggageCount, 0);
        expect(stats.totalExpenses, 0.0);
        expect(stats.nbTravelers, 1);
        expect(stats.daysUntilTrip, isNull);
        expect(stats.tripDuration, isNull);
      });
    });

    group('toJson', () {
      test('roundtrip produces equal object', () {
        final stats = const TripHomeStats(
          baggageCount: 5,
          totalExpenses: 300.0,
          nbTravelers: 2,
          daysUntilTrip: 15,
          tripDuration: 10,
        );

        final json = stats.toJson();
        final restored = TripHomeStats.fromJson(json);

        expect(restored, stats);
      });
    });

    group('equality', () {
      test('two stats with same fields are equal', () {
        final s1 = const TripHomeStats(baggageCount: 3, nbTravelers: 2);
        final s2 = const TripHomeStats(baggageCount: 3, nbTravelers: 2);
        expect(s1, s2);
      });

      test('two stats with different fields are not equal', () {
        final s1 = const TripHomeStats(baggageCount: 3);
        final s2 = const TripHomeStats(baggageCount: 5);
        expect(s1, isNot(s2));
      });
    });

    group('copyWith', () {
      test('copies with changed fields', () {
        const stats = TripHomeStats();
        final updated = stats.copyWith(baggageCount: 10, totalExpenses: 500.0);

        expect(updated.baggageCount, 10);
        expect(updated.totalExpenses, 500.0);
        expect(updated.nbTravelers, 1);
      });
    });
  });

  // ---------------------------------------------------------------------------
  // TripFeatureTile
  // ---------------------------------------------------------------------------
  group('TripFeatureTile', () {
    group('fromJson', () {
      test('parses all fields correctly', () {
        final json = <String, dynamic>{
          'id': 'feat-1',
          'label': 'Budget',
          'icon': 'wallet',
          'route': '/trip/budget',
          'enabled': true,
        };

        final tile = TripFeatureTile.fromJson(json);

        expect(tile.id, 'feat-1');
        expect(tile.label, 'Budget');
        expect(tile.icon, 'wallet');
        expect(tile.route, '/trip/budget');
        expect(tile.enabled, true);
      });

      test('applies default for enabled', () {
        final json = <String, dynamic>{
          'id': 'feat-2',
          'label': 'Activities',
          'icon': 'hiking',
          'route': '/trip/activities',
        };

        final tile = TripFeatureTile.fromJson(json);

        expect(tile.id, 'feat-2');
        expect(tile.enabled, false);
      });
    });

    group('toJson', () {
      test('roundtrip produces equal object', () {
        final tile = const TripFeatureTile(
          id: 'feat-rt',
          label: 'Baggage',
          icon: 'suitcase',
          route: '/trip/baggage',
          enabled: true,
        );

        final json = tile.toJson();
        final restored = TripFeatureTile.fromJson(json);

        expect(restored, tile);
      });
    });

    group('equality', () {
      test('two tiles with same fields are equal', () {
        final t1 = const TripFeatureTile(
          id: 'f1',
          label: 'A',
          icon: 'i',
          route: '/r',
        );
        final t2 = const TripFeatureTile(
          id: 'f1',
          label: 'A',
          icon: 'i',
          route: '/r',
        );
        expect(t1, t2);
      });

      test('two tiles with different fields are not equal', () {
        final t1 = const TripFeatureTile(
          id: 'f1',
          label: 'A',
          icon: 'i',
          route: '/r',
        );
        final t2 = const TripFeatureTile(
          id: 'f2',
          label: 'A',
          icon: 'i',
          route: '/r',
        );
        expect(t1, isNot(t2));
      });
    });

    group('copyWith', () {
      test('copies with changed fields', () {
        final tile = const TripFeatureTile(
          id: 'f1',
          label: 'Old',
          icon: 'old_icon',
          route: '/old',
        );
        final updated = tile.copyWith(label: 'New', enabled: true);

        expect(updated.id, 'f1');
        expect(updated.label, 'New');
        expect(updated.enabled, true);
        expect(updated.route, '/old');
      });
    });
  });

  // ---------------------------------------------------------------------------
  // TripHome
  // ---------------------------------------------------------------------------
  group('TripHome', () {
    group('fromJson', () {
      test('parses all fields correctly', () {
        final json = <String, dynamic>{
          'trip': {
            'id': 'trip-1',
            'userId': 'user-1',
            'title': 'Paris Trip',
            'status': 'ongoing',
          },
          'stats': {
            'baggageCount': 5,
            'totalExpenses': 200.0,
            'nbTravelers': 2,
          },
          'features': [
            {
              'id': 'f1',
              'label': 'Budget',
              'icon': 'wallet',
              'route': '/budget',
              'enabled': true,
            },
            {
              'id': 'f2',
              'label': 'Baggage',
              'icon': 'suitcase',
              'route': '/baggage',
            },
          ],
        };

        final home = TripHome.fromJson(json);

        expect(home.trip.id, 'trip-1');
        expect(home.trip.title, 'Paris Trip');
        expect(home.trip.status, TripStatus.ongoing);
        expect(home.stats.baggageCount, 5);
        expect(home.stats.totalExpenses, 200.0);
        expect(home.stats.nbTravelers, 2);
        expect(home.features.length, 2);
        expect(home.features[0].label, 'Budget');
        expect(home.features[0].enabled, true);
        expect(home.features[1].label, 'Baggage');
        expect(home.features[1].enabled, false);
      });
    });

    group('toJson', () {
      test('roundtrip produces equal object', () {
        final home = const TripHome(
          trip: Trip(
            id: 'trip-rt',
            userId: 'user-rt',
            title: 'Test Trip',
            status: TripStatus.planned,
          ),
          stats: TripHomeStats(baggageCount: 3, totalExpenses: 100.0),
          features: [
            TripFeatureTile(
              id: 'f1',
              label: 'Activities',
              icon: 'star',
              route: '/activities',
              enabled: true,
            ),
          ],
        );

        final json = home.toJson();
        final restored = TripHome.fromJson(json);

        expect(restored, home);
      });
    });

    group('equality', () {
      test('two homes with same fields are equal', () {
        final trip = const Trip(id: 't1', userId: 'u1');
        const stats = TripHomeStats();
        final features = [
          const TripFeatureTile(id: 'f1', label: 'A', icon: 'i', route: '/r'),
        ];

        final h1 = TripHome(trip: trip, stats: stats, features: features);
        final h2 = TripHome(trip: trip, stats: stats, features: features);
        expect(h1, h2);
      });
    });

    group('copyWith', () {
      test('copies with changed fields', () {
        final home = const TripHome(
          trip: Trip(id: 't1', userId: 'u1'),
          stats: TripHomeStats(),
          features: [],
        );
        final newStats = const TripHomeStats(baggageCount: 10);
        final updated = home.copyWith(stats: newStats);

        expect(updated.trip.id, 't1');
        expect(updated.stats.baggageCount, 10);
        expect(updated.features, <TripFeatureTile>[]);
      });
    });
  });
}
