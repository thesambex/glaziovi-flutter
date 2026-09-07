// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_page_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(HomePageViewModel)
final homePageViewModelProvider = HomePageViewModelProvider._();

final class HomePageViewModelProvider
    extends $AsyncNotifierProvider<HomePageViewModel, List<ActivitySummary>> {
  HomePageViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homePageViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homePageViewModelHash();

  @$internal
  @override
  HomePageViewModel create() => HomePageViewModel();
}

String _$homePageViewModelHash() => r'0ef63b26b94b9d8e146bfb773d5a497ef1af2483';

abstract class _$HomePageViewModel
    extends $AsyncNotifier<List<ActivitySummary>> {
  FutureOr<List<ActivitySummary>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<ActivitySummary>>, List<ActivitySummary>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<ActivitySummary>>,
                List<ActivitySummary>
              >,
              AsyncValue<List<ActivitySummary>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
