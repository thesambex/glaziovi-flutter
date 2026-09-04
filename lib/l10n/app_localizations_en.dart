// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get startHint => 'Start';

  @override
  String get okHint => 'OK';

  @override
  String get errorTitle => 'Something went wrong';

  @override
  String get pauseHint => 'Pause';

  @override
  String get resumeHint => 'Resume';

  @override
  String get finishHint => 'Finish';

  @override
  String get resetHint => 'New activity';

  @override
  String get timeHint => 'Time';

  @override
  String get kilometersHint => 'Kilometers';

  @override
  String get locationServiceDisabledError => 'Enable device location';

  @override
  String get locationPermissionDeniedError => 'Location permission denied';

  @override
  String get locationPermissionDeniedForeverError =>
      'Location permission permanently denied, enable it in the device settings';

  @override
  String get backgroundLocationPermissionDeniedError =>
      'Enable background location permission to record activity in background';

  @override
  String get unknownError => 'Something went wrong, please try again';

  @override
  String get recordingNotificationTitle => 'Activity in progress';

  @override
  String get recordingNotificationText =>
      'Glaziovi is recording your location.';
}
