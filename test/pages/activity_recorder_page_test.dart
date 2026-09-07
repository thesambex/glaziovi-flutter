import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:glaziovi/activity/activity_data.dart';
import 'package:glaziovi/activity/activity_event.dart';
import 'package:glaziovi/activity/activity_track_point.dart';
import 'package:glaziovi/activity/data-access/activity_dao.dart';
import 'package:glaziovi/features/activity-recorder/activity_recorder_page.dart';
import 'package:glaziovi/features/activity-recorder/activity_recorder_state.dart';
import 'package:glaziovi/features/activity-recorder/activity_recorder_view_model.dart';
import 'package:glaziovi/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

void main() {
  group('ActivityRecorderPage', () {
    late _MemoryActivityDAO dao;
    late _FakeGeolocator gps;

    late GeolocatorPlatform originalGps;
    late ProviderContainer container;

    late GoRouter router;

    ActivityState currentState() =>
        container.read(activityRecorderViewModelProvider);

    setUp(() {
      dao = _MemoryActivityDAO();

      originalGps = GeolocatorPlatform.instance;
    });

    tearDown(() async {
      GeolocatorPlatform.instance = originalGps;
      await gps.positions.close();
    });

    Future<void> openRecorder(WidgetTester tester) async {
      gps = _FakeGeolocator();
      GeolocatorPlatform.instance = gps;

      router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('Home')),
          ),
          GoRoute(
            path: '/record',
            builder: (_, _) =>
                ActivityRecorderPage(tileProvider: _MemoryTiles()),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [activityDaoProvider.overrideWith((ref) async => dao)],
          child: MaterialApp.router(
            routerConfig: router,
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );

      router.push('/record');

      await tester.pumpAndSettle();

      container = ProviderScope.containerOf(
        tester.element(find.byType(ActivityRecorderPage)),
        listen: false,
      );

      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        router.dispose();
      });

      expect(currentState().error, isNull);
      expect(find.byType(AlertDialog), findsNothing);
    }

    Future<void> tapLabel(WidgetTester tester, String label) async {
      final finder = find.text(label);
      expect(finder.hitTestable(), findsOneWidget);

      await tester.tap(finder);

      // Stream cancellation can complete outside the widget fake-async zone.
      await tester.runAsync(() async {
        await Future<void>.delayed(Duration.zero);
      });

      await tester.pumpAndSettle();
    }

    Future<void> startActivity(WidgetTester tester) async {
      await tapLabel(tester, 'Select sport');

      final sport = find.text('Street running');

      await tester.ensureVisible(sport);
      await tester.pumpAndSettle();
      await tapLabel(tester, 'Street running');

      expect(currentState().isReady, isTrue);

      await tapLabel(tester, 'Start');

      expect(currentState().status, ActivityStatus.recording);
    }

    Future<void> recordPoints(WidgetTester tester) async {
      gps.positions.add(gps.position());

      await tester.pump();

      gps.positions.add(gps.position(latitude: -13.00005, seconds: 2));

      await tester.pump();
      expect(currentState().distanceMeters, greaterThan(0));
      expect(currentState().route, hasLength(2));
    }

    void expectCleared() {
      final state = currentState();
      expect(state.status, ActivityStatus.idle);
      expect(state.startedAt, isNull);
      expect(state.finishedAt, isNull);
      expect(state.elapsed, Duration.zero);
      expect(state.distanceMeters, 0);
      expect(state.averageSpeedKmh, 0);
      expect(state.route, isEmpty);
      expect(state.selectedSport, isNull);
      expect(gps.positions.hasListener, isFalse);
    }

    group('start', () {
      testWidgets('starts idle with Start disabled until a sport is selected', (
        tester,
      ) async {
        await openRecorder(tester);

        expect(currentState().status, ActivityStatus.idle);
        expect(currentState().isReady, isFalse);

        final button = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Start'),
        );

        expect(button.onPressed, isNull);
      });

      testWidgets('starts the selected sport and persists recording status', (
        tester,
      ) async {
        await openRecorder(tester);

        final statuses = <ActivityStatus>[];
        final subscription = container.listen(
          activityRecorderViewModelProvider,
          (_, next) => statuses.add(next.status),
          fireImmediately: true,
        );

        addTearDown(subscription.close);

        await startActivity(tester);

        expect(
          statuses,
          containsAllInOrder([ActivityStatus.idle, ActivityStatus.recording]),
        );

        expect(dao.activity!.status, ActivityRecordStatus.recording);
        expect(currentState().startedAt, isNotNull);
        expect(gps.positions.hasListener, isTrue);
        expect(find.text('Pause'), findsOneWidget);
      });
    });

    group('pause and resume', () {
      testWidgets('pauses recording and stops receiving positions', (
        tester,
      ) async {
        await openRecorder(tester);
        await startActivity(tester);
        await recordPoints(tester);
        await tapLabel(tester, 'Pause');

        expect(currentState().status, ActivityStatus.paused);
        expect(dao.activity!.status, ActivityRecordStatus.paused);
        expect(gps.positions.hasListener, isFalse);

        final elapsed = currentState().elapsed;
        final distance = currentState().distanceMeters;

        await tester.pump(const Duration(seconds: 3));

        expect(currentState().elapsed, elapsed);
        expect(currentState().distanceMeters, distance);
        expect(find.text('Resume'), findsOneWidget);
        expect(find.text('Finish'), findsOneWidget);
      });

      testWidgets('resumes the same activity and receives positions again', (
        tester,
      ) async {
        await openRecorder(tester);
        await startActivity(tester);
        await recordPoints(tester);
        await tapLabel(tester, 'Pause');

        final id = dao.activity!.id;
        final distance = currentState().distanceMeters;

        await tapLabel(tester, 'Resume');

        expect(currentState().status, ActivityStatus.recording);
        expect(dao.activity!.id, id);
        expect(dao.activity!.status, ActivityRecordStatus.recording);
        expect(currentState().distanceMeters, distance);
        expect(gps.positions.hasListener, isTrue);
        gps.positions.add(gps.position(seconds: 4));

        await tester.pump();

        expect(currentState().route, hasLength(3));
        expect(find.text('Pause'), findsOneWidget);
        expect(find.text('Finish'), findsNothing);
      });
    });

    group('finish', () {
      testWidgets('saves as finished, clears state and returns home', (
        tester,
      ) async {
        await openRecorder(tester);
        await startActivity(tester);
        await recordPoints(tester);
        await tapLabel(tester, 'Pause');

        final distance = currentState().distanceMeters;

        await tapLabel(tester, 'Finish');

        expectCleared();
        expect(dao.activity!.status, ActivityRecordStatus.finished);
        expect(dao.activity!.finishedAtMs, isNotNull);
        expect(dao.activity!.distanceM, distance);
        expect(find.text('Home'), findsOneWidget);
        router.push('/record');

        await tester.pumpAndSettle();

        expectCleared();
        expect(find.text('Select sport'), findsOneWidget);
        expect(find.text('00:00:00'), findsOneWidget);
      });
    });

    group('delete', () {
      testWidgets('cancel keeps the current activity recording', (
        tester,
      ) async {
        await openRecorder(tester);
        await startActivity(tester);
        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);

        await tapLabel(tester, 'Cancel');

        expect(dao.activity, isNotNull);
        expect(currentState().status, ActivityStatus.recording);
        expect(gps.positions.hasListener, isTrue);
        expect(find.byType(AlertDialog), findsNothing);
      });

      for (final paused in [false, true]) {
        testWidgets(
          'confirmation deletes ${paused ? 'paused' : 'recording'} activity and clears state',
          (tester) async {
            await openRecorder(tester);
            await startActivity(tester);
            await recordPoints(tester);

            if (paused) await tapLabel(tester, 'Pause');

            await tester.tap(find.byIcon(Icons.delete_outline));
            await tester.pumpAndSettle();
            await tapLabel(tester, 'Abandon');

            expect(dao.activity, isNull);
            expectCleared();
            expect(find.text('Home'), findsOneWidget);

            await tester.pump(const Duration(seconds: 31));

            expectCleared();
            router.push('/record');

            await tester.pumpAndSettle();

            expect(find.text('00:00:00'), findsOneWidget);

            await startActivity(tester);

            expect(dao.activity!.id, 2);
          },
        );
      }
    });
  });
}

// Keep the real ViewModel: only replace device and storage dependencies.
class _MemoryActivityDAO extends Fake implements ActivityDAO {
  ActivityData? activity;
  int _nextId = 1;

  @override
  Future<ActivityData?> findUnfinished() async => null;

  @override
  Future<ActivityData> createData(ActivityData data) async {
    return activity = data.copyWith(id: _nextId++);
  }

  @override
  Future<void> updateLifecycle(
    int activityId, {
    required ActivityRecordStatus status,
    required int startedAtMs,
    int? finishedAtMs,
  }) async {
    expect(activity!.id, activityId);

    activity = activity!.copyWith(
      status: status,
      startedAtMs: startedAtMs,
      finishedAtMs: finishedAtMs,
    );
  }

  @override
  Future<void> appendChunk({
    required int activityId,
    required List<ActivityTrackPoint> points,
    required List<ActivityEvent> events,
    required double distanceM,
    required Duration elapsed,
    required Duration timer,
  }) async {
    expect(activity, isNotNull, reason: 'Must not write after deletion');
    expect(activity!.id, activityId);

    activity = activity!.copyWith(
      distanceM: distanceM,
      elapsedMs: elapsed.inMilliseconds,
      timerMs: timer.inMilliseconds,
    );
  }

  @override
  Future<void> deleteActivity(int activityId) async {
    expect(activity!.id, activityId);
    activity = null;
  }
}

class _FakeGeolocator extends GeolocatorPlatform {
  final positions = StreamController<Position>.broadcast();

  Position position({double latitude = -13, int seconds = 0}) => Position(
    latitude: latitude,
    longitude: -41,
    timestamp: DateTime(2026, 1, 1).add(Duration(seconds: seconds)),
    accuracy: 5,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.always;

  @override
  Future<Position?> getLastKnownPosition({
    bool forceLocationManager = false,
  }) async => position();

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async => position();

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) =>
      positions.stream;
}

class _MemoryTiles extends TileProvider {
  final _image = MemoryImage(
    base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
    ),
  );

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      _image;
}
