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
  String get exportFitFileHint => 'Export to FIT';

  @override
  String get activityNameHint => 'Activity name';

  @override
  String get activityNameRequired => 'Enter an activity name';

  @override
  String get resetHint => 'New activity';

  @override
  String get timeHint => 'Time';

  @override
  String get kilometersHint => 'Kilometers';

  @override
  String get activityHint => 'Activity';

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

  @override
  String distanceWithUnitHint(String unit) {
    return 'Distance ($unit)';
  }

  @override
  String avgSpeedWithUnitHint(String unit) {
    return 'AVG Speed ($unit)';
  }

  @override
  String get activitySelectSport => 'Select sport';

  @override
  String get activityRecorderDeleteHint =>
      'Are you sure you want to abandon the current activity?';

  @override
  String get activityRecorderAbandonTitle => 'Abandon activity?';

  @override
  String get activityRecorderAbandonAction => 'Abandon';

  @override
  String get cancelHint => 'Cancel';

  @override
  String get activityTypeCycling => 'Cycling';

  @override
  String get activityTypeGeneric => 'Other sports';

  @override
  String get activityTypeFitnessEquipment => 'Fitness equipment';

  @override
  String get activitySubTypeTreadmill => 'Treadmill';

  @override
  String get activitySubTypeIndoorWalking => 'Indoor walking';

  @override
  String get activitySubTypeSpeedWalking => 'Speed walking';

  @override
  String get activitySubTypeSpin => 'Spinning';

  @override
  String get activitySubTypeIndoorCycling => 'Indoor cycling';

  @override
  String get activityTypeRunning => 'Running';

  @override
  String get activityTypeWalking => 'Walking';

  @override
  String get activitySubTypeGeneric => 'Traditional';

  @override
  String get activitySubTypeRunStreet => 'Street running';

  @override
  String get activitySubTypeRunTrail => 'Trail running';

  @override
  String get activitySubTypeRunTrack => 'Track running';

  @override
  String get activitySubTypeWalkCasual => 'Casual walking';

  @override
  String get activitySubTypeCycleRoad => 'Road';

  @override
  String get activitySubTypeCycleMountain => 'Mountain bike';
}
