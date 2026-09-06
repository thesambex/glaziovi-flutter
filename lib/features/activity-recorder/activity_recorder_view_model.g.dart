// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_recorder_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ActivityRecorderViewModel)
final activityRecorderViewModelProvider = ActivityRecorderViewModelProvider._();

final class ActivityRecorderViewModelProvider
    extends $NotifierProvider<ActivityRecorderViewModel, ActivityState> {
  ActivityRecorderViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activityRecorderViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activityRecorderViewModelHash();

  @$internal
  @override
  ActivityRecorderViewModel create() => ActivityRecorderViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ActivityState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ActivityState>(value),
    );
  }
}

String _$activityRecorderViewModelHash() =>
    r'036a7d114efe0f321e79fc24fc77a48011dcb35f';

abstract class _$ActivityRecorderViewModel extends $Notifier<ActivityState> {
  ActivityState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ActivityState, ActivityState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ActivityState, ActivityState>,
              ActivityState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
