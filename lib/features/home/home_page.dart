import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glaziovi/features/home/home_page_view_model.dart';
import 'package:go_router/go_router.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HomeViewState();
}

// Temporary way to list and export activities
class _HomeViewState extends ConsumerState<HomePage> {
  @override
  Widget build(BuildContext context) {
    final activitiesAsync = ref.watch(homePageViewModelProvider);

    return Scaffold(
      body: activitiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        data: (activities) {
          return ListView.builder(
            itemCount: activities.length,
            itemBuilder: (context, index) {
              return InkWell(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text('Activity ${index + 1}'),
                  ),
                ),
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
