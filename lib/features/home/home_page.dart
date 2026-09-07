import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glaziovi/activity/activity_summary.dart';
import 'package:glaziovi/features/home/home_page_view_model.dart';
import 'package:glaziovi/l10n/app_localizations.dart';
import 'package:glaziovi/navigation/app_route_observer.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HomeViewState();
}

// Temporary way to list and export activities
class _HomeViewState extends ConsumerState<HomePage> with RouteAware {
  PageRoute<dynamic>? _route;
  bool _refreshScheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<dynamic> && route != _route) {
      appRouteObserver.unsubscribe(this);
      _route = route;
      appRouteObserver.subscribe(this, route);
    }
  }

  void _refreshActivities() {
    if (_refreshScheduled) return;
    _refreshScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshScheduled = false;
      if (mounted) ref.invalidate(homePageViewModelProvider);
    });
  }

  @override
  void didPush() => _refreshActivities();

  @override
  void didPopNext() => _refreshActivities();

  @override
  void didPushNext() => _refreshActivities();

  @override
  void didPop() => _refreshActivities();

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activitiesAsync = ref.watch(homePageViewModelProvider);
    final viewModel = ref.read(homePageViewModelProvider.notifier);

    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: activitiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        data: (activities) {
          return ListView.builder(
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final summary = activities[index];

              return _ActivityCard(
                summary: summary,
                viewModel: viewModel,
                l10n: l10n,
              );
            },
          );
        },
        error: (Object error, StackTrace stackTrace) {
          return const Text('Activities not found');
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => context.go('/activity-recorder'),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this._summary,
    required this._viewModel,
    required this._l10n,
  });

  final ActivitySummary _summary;
  final HomePageViewModel _viewModel;
  final AppLocalizations _l10n;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          spacing: 8,
          children: [
            Text(_summary.name),
            PopupMenuButton<int>(
              icon: const Icon(Icons.more_vert_outlined),
              onSelected: (value) {
                if (value == 1) {
                  _viewModel.exportToFit(
                    activityId: _summary.activityDataId,
                    onExported: (path) async {
                      final xFile = XFile(path, mimeType: 'application/fits');
                      final shareParams = ShareParams(files: [xFile]);

                      await SharePlus.instance.share(shareParams);
                    },
                  );
                }
              },
              itemBuilder: (context) => <PopupMenuEntry<int>>[
                PopupMenuItem(value: 1, child: Text(_l10n.exportFitFileHint)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
