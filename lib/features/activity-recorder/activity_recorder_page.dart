import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:glaziovi/features/activity-recorder/activity_error_l10n.dart';
import 'package:glaziovi/features/activity-recorder/activity_recorder_state.dart';
import 'package:glaziovi/features/activity-recorder/activity_recorder_view_model.dart';
import 'package:glaziovi/l10n/app_localizations.dart';
import 'package:latlong2/latlong.dart';

const _initialCenter = LatLng(-13.007316938533874, -41.376938721927566);
const _initialZoom = 12.0;
const _userZoom = 17.0;

class ActivityRecorderPage extends ConsumerStatefulWidget {
  const ActivityRecorderPage({super.key});

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
    final state = ref.watch(activityRecorderViewModelProvider);

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

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: IndexedStack(
                index: state.view.index,
                children: [
                  _MapView(
                    mapController: _mapController,
                    state: state,
                    onMapReady: _onMapReady,
                  ),
                  _MetricsView(state: state),
                ],
              ),
            ),

            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: _ActivityControls(state: state),
            ),
          ],
        ),
      ),
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
    required this.mapController,
    required this.state,
    required this.onMapReady,
  });

  final MapController mapController;
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

class _MetricsView extends StatelessWidget {
  const _MetricsView({required this.state});

  final ActivityState state;

  // TODO: Create metrics view

  @override
  Widget build(BuildContext context) {
    return ColoredBox(color: Theme.of(context).colorScheme.surface);
  }
}

class _ActivityControls extends ConsumerWidget {
  const _ActivityControls({required this.state});

  final ActivityState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(activityRecorderViewModelProvider.notifier);

    final l10n = AppLocalizations.of(context)!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Tooltip(
          message: switch (state.status) {
            ActivityStatus.idle => l10n.startHint,
            ActivityStatus.recording => l10n.pauseHint,
            ActivityStatus.paused => l10n.resumeHint,
            ActivityStatus.finished => l10n.resetHint,
          },
          child: FilledButton(
            style: FilledButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(24),
            ),
            onPressed: switch (state.status) {
              ActivityStatus.idle => viewModel.start,
              ActivityStatus.recording => viewModel.pause,
              ActivityStatus.paused => viewModel.resume,
              ActivityStatus.finished => viewModel.reset,
            },
            child: Icon(switch (state.status) {
              ActivityStatus.idle => Icons.play_arrow_rounded,
              ActivityStatus.recording => Icons.pause_rounded,
              ActivityStatus.paused => Icons.play_arrow_rounded,
              ActivityStatus.finished => Icons.sync_rounded,
            }, size: 42),
          ),
        ),

        if (state.status == ActivityStatus.paused) ...[
          const SizedBox(width: 16),
          Tooltip(
            message: l10n.finishHint,
            child: FilledButton(
              style: FilledButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(24),
              ),
              onPressed: viewModel.finish,
              child: const Icon(Icons.stop_rounded, size: 24),
            ),
          ),
        ],
      ],
    );
  }
}
