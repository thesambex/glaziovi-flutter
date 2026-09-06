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
    extends $AsyncNotifierProvider<HomePageViewModel, List<ActivityData>> {
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

String _$homePageViewModelHash() => r'155611c6c6745309296e81c304a14e65924746bb';

abstract class _$HomePageViewModel extends $AsyncNotifier<List<ActivityData>> {
  FutureOr<List<ActivityData>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<ActivityData>>, List<ActivityData>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<ActivityData>>, List<ActivityData>>,
              AsyncValue<List<ActivityData>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
