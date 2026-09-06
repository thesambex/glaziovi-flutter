import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:glaziovi/features/activity-recorder/activity_error_l10n.dart';
import 'package:glaziovi/features/activity-recorder/activity_recorder_state.dart';
import 'package:glaziovi/features/activity-recorder/activity_recorder_view_model.dart';
import 'package:glaziovi/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:glaziovi/activity/activity_sport.dart';
import 'package:glaziovi/features/activity-recorder/activity_sport_picker.dart';

const _initialCenter = LatLng(-13.007316938533874, -41.376938721927566);
const _initialZoom = 13.0;
const _userZoom = 18.0;

class ActivityRecorderPage extends ConsumerStatefulWidget {
  const ActivityRecorderPage({super.key, this.tileProvider});

  final TileProvider? tileProvider;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ActivityRecorderState();
}

class _ActivityRecorderState extends ConsumerState<ActivityRecorderPage> {
  final _mapController = MapController();

  bool _isMapReady = false;
  bool _hasCenteredOnUser = false;
  bool _isShowingError = false;

  @override
  void initState() {
    super.initState();

    Future.microtask(
      () => ref.read(activityRecorderViewModelProvider.notifier).initialize(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.read(activityRecorderViewModelProvider);

    ref.watch(
      activityRecorderViewModelProvider.select(
        (state) =>
            (state.view, state.status, state.currentPosition, state.route),
      ),
    );

    ref.listen(
      activityRecorderViewModelProvider.select(
        (state) => state.currentPosition,
      ),
      (previous, current) {
        if (current == null) return;

        _centerOnUser(current);
      },
    );

    ref.listen(
      activityRecorderViewModelProvider.select((state) => state.error),
      (previous, current) {
        if (current == null) return;

        _showError(current);
      },
    );

    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.activityHint),
        centerTitle: true,
        actions: [
          if (state.hasStarted)
            IconButton(
              onPressed: _confirmAbandonActivity,
              icon: Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: IndexedStack(
                index: state.view.index,
                children: [
                  _MapView(
                    tileProvider: widget.tileProvider,
                    mapController: _mapController,
                    state: state,
                    onMapReady: _onMapReady,
                  ),
                ],
              ),
            ),

            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _ActivityDuration(),
            ),

            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _ActivityControls(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAbandonActivity() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.activityRecorderAbandonTitle),
        content: Text(l10n.activityRecorderDeleteHint),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancelHint),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: Text(l10n.activityRecorderAbandonAction),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await ref.read(activityRecorderViewModelProvider.notifier).deleteActivity(
      () {
        if (mounted) context.go('/');
      },
    );
  }

  void _onMapReady() {
    _isMapReady = true;

    final position = ref
        .read(activityRecorderViewModelProvider)
        .currentPosition;
    if (position != null) {
      _centerOnUser(position);
    }
  }

  Future<void> _showError(ActivityError error) async {
    if (_isShowingError) return;

    _isShowingError = true;

    final l10n = AppLocalizations.of(context)!;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.errorTitle),
        content: Text(error.message(l10n)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.okHint),
          ),
        ],
      ),
    );

    _isShowingError = false;

    if (!mounted) return;

    ref.read(activityRecorderViewModelProvider.notifier).clearError();
  }

  void _centerOnUser(Position position) {
    if (!_isMapReady || _hasCenteredOnUser) return;

    _hasCenteredOnUser = true;
    _mapController.move(
      LatLng(position.latitude, position.longitude),
      _userZoom,
    );
  }
}

class _MapView extends StatelessWidget {
  const _MapView({
    this.tileProvider,
    required this.mapController,
    required this.state,
    required this.onMapReady,
  });

  final MapController mapController;
  final TileProvider? tileProvider;
  final ActivityState state;
  final VoidCallback onMapReady;

  @override
  Widget build(BuildContext context) {
    final position = state.currentPosition;

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: _initialCenter,
        initialZoom: _initialZoom,
        onMapReady: onMapReady,
      ),
      children: [
        TileLayer(
          tileProvider: tileProvider,
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'glaziovi.app',
        ),

        PolylineLayer(
          polylines: [
            if (state.route.length >= 2)
              Polyline(
                points: state.route,
                strokeWidth: 5,
                color: Theme.of(context).colorScheme.primary,
              ),
          ],
        ),

        if (position != null)
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(position.latitude, position.longitude),
                width: 32,
                height: 32,
                child: Icon(
                  Icons.my_location,
                  color: Theme.of(context).colorScheme.primary,
                  size: 30,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _ActivityDuration extends ConsumerStatefulWidget {
  const _ActivityDuration();

  @override
  ConsumerState<_ActivityDuration> createState() => _ActivityDurationState();
}

class _ActivityDurationState extends ConsumerState<_ActivityDuration> {
  Timer? _timer;
  bool _isSelectingSport = false;

  Future<void> _selectSport() async {
    if (_isSelectingSport) return;
    setState(() => _isSelectingSport = true);
    try {
      final selected = await showModalBottomSheet<ActivitySport>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (context) => FractionallySizedBox(
          heightFactor: 0.8,
          child: const ActivitySportPicker(),
        ),
      );
      if (selected == null || !mounted) return;
      await ref
          .read(activityRecorderViewModelProvider.notifier)
          .createActivity(selected.sport!, selected.subSport!);
    } catch (_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ActivityError.unknown.message(l10n))),
      );
    } finally {
      if (mounted) setState(() => _isSelectingSport = false);
    }
  }

  @override
  void initState() {
    super.initState();
    ref.listenManual(
      activityRecorderViewModelProvider.select(
        (state) => (state.startedAt, state.finishedAt),
      ),
      (previous, current) {
        _timer?.cancel();
        if (current.$1 != null && current.$2 == null) {
          _timer = Timer.periodic(const Duration(seconds: 1), (_) {
            setState(() {});
          });
        }
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final (startedAt, finishedAt) = ref.watch(
      activityRecorderViewModelProvider.select(
        (state) => (state.startedAt, state.finishedAt),
      ),
    );
    final duration = startedAt == null
        ? Duration.zero
        : (finishedAt ?? DateTime.now()).difference(startedAt);
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');

    final selectedSport = ref.watch(
      activityRecorderViewModelProvider.select((state) => state.selectedSport),
    );

    return ColoredBox(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 12,
          children: [
            selectedSport != null
                ? Text(
                    '${selectedSport.sport?.label(l10n) ?? l10n.activityTypeGeneric} · ${selectedSport.subSport?.label(l10n) ?? l10n.activitySubTypeGeneric}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  )
                : InkWell(
                    onTap: _isSelectingSport ? null : _selectSport,
                    child: Text(
                      l10n.activitySelectSport,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),

            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.timeHint,
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                ),

                Text(
                  '$hours:$minutes:$seconds',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 32,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityControls extends ConsumerStatefulWidget {
  const _ActivityControls();

  @override
  ConsumerState<_ActivityControls> createState() => _ActivityControlsState();
}

class _ActivityControlsState extends ConsumerState<_ActivityControls> {
  bool _isExecuting = false;

  Future<void> _execute(Future<void> Function() action) async {
    if (_isExecuting) return;
    setState(() => _isExecuting = true);
    try {
      await action();
    } catch (_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ActivityError.unknown.message(l10n))),
      );
    } finally {
      if (mounted) setState(() => _isExecuting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final (status, distanceMeters, averageSpeedKmh, startedAt, isLoading) = ref
        .watch(
          activityRecorderViewModelProvider.select(
            (state) => (
              state.status,
              state.distanceMeters,
              state.averageSpeedKmh,
              state.startedAt,
              state.isLoadingLocation,
            ),
          ),
        );

    final viewModel = ref.read(activityRecorderViewModelProvider.notifier);
    final isReady = ref.watch(
      activityRecorderViewModelProvider.select((state) => state.isReady),
    );
    final format = NumberFormat('0.00', l10n.localeName);
    final isDisabled =
        _isExecuting ||
        isLoading ||
        (status == ActivityStatus.idle && !isReady);

    final action = switch (status) {
      ActivityStatus.idle => viewModel.start,
      ActivityStatus.recording => viewModel.pause,
      ActivityStatus.paused => viewModel.resume,
      ActivityStatus.finished => viewModel.reset,
    };

    final actionLabel = switch (status) {
      ActivityStatus.idle => l10n.startHint,
      ActivityStatus.recording => l10n.pauseHint,
      ActivityStatus.paused => l10n.resumeHint,
      ActivityStatus.finished => l10n.resetHint,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ColoredBox(
          color: Colors.white,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // TODO: add dynamic unit types
                Column(
                  children: [
                    Text(
                      l10n.distanceWithUnitHint('Km'),
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      format.format(distanceMeters / 1000),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 48,
                  child: VerticalDivider(color: Color(0xff9D9D9D)),
                ),

                Column(
                  children: [
                    Text(
                      l10n.avgSpeedWithUnitHint('Km/h'),
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      format.format(averageSpeedKmh),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        ColoredBox(
          color: Theme.of(context).colorScheme.primary,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              spacing: 16,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                FilledButton(
                  style: FilledButton.styleFrom(
                    foregroundColor: Color(0xff3B3B3B),
                    backgroundColor: Colors.white,
                  ),
                  onPressed: isDisabled ? null : () => _execute(action),
                  child: Text(actionLabel),
                ),

                if (status == ActivityStatus.paused && startedAt != null)
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Color(0xff3B3B3B),
                    ),
                    onPressed: isDisabled
                        ? null
                        : () => _execute(
                            () => viewModel.finish(() {
                              if (context.mounted) Navigator.pop(context);
                            }),
                          ),
                    child: Text(l10n.finishHint),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
