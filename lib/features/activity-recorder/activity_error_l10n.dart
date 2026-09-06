import 'package:glaziovi/features/activity-recorder/activity_recorder_state.dart';
import 'package:glaziovi/l10n/app_localizations.dart';

extension ActivityErrorL10n on ActivityError {
  String message(AppLocalizations l10n) => switch (this) {
    ActivityError.locationServiceDisabled => l10n.locationServiceDisabledError,
    ActivityError.locationPermissionDenied =>
      l10n.locationPermissionDeniedError,
    ActivityError.locationPermissionDeniedForever =>
      l10n.locationPermissionDeniedForeverError,
    ActivityError.backgroundLocationPermissionDenied =>
      l10n.backgroundLocationPermissionDeniedError,
    ActivityError.unknown => l10n.unknownError,
  };
}
