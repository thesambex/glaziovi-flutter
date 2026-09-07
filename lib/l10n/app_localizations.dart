import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @startHint.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startHint;

  /// No description provided for @okHint.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get okHint;

  /// No description provided for @errorTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorTitle;

  /// No description provided for @pauseHint.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pauseHint;

  /// No description provided for @resumeHint.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resumeHint;

  /// No description provided for @finishHint.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finishHint;

  /// No description provided for @exportFitFileHint.
  ///
  /// In en, this message translates to:
  /// **'Export to FIT'**
  String get exportFitFileHint;

  /// No description provided for @activityNameHint.
  ///
  /// In en, this message translates to:
  /// **'Activity name'**
  String get activityNameHint;

  /// No description provided for @activityNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter an activity name'**
  String get activityNameRequired;

  /// No description provided for @resetHint.
  ///
  /// In en, this message translates to:
  /// **'New activity'**
  String get resetHint;

  /// No description provided for @timeHint.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get timeHint;

  /// No description provided for @kilometersHint.
  ///
  /// In en, this message translates to:
  /// **'Kilometers'**
  String get kilometersHint;

  /// No description provided for @activityHint.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activityHint;

  /// No description provided for @locationServiceDisabledError.
  ///
  /// In en, this message translates to:
  /// **'Enable device location'**
  String get locationServiceDisabledError;

  /// No description provided for @locationPermissionDeniedError.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied'**
  String get locationPermissionDeniedError;

  /// No description provided for @locationPermissionDeniedForeverError.
  ///
  /// In en, this message translates to:
  /// **'Location permission permanently denied, enable it in the device settings'**
  String get locationPermissionDeniedForeverError;

  /// No description provided for @backgroundLocationPermissionDeniedError.
  ///
  /// In en, this message translates to:
  /// **'Enable background location permission to record activity in background'**
  String get backgroundLocationPermissionDeniedError;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong, please try again'**
  String get unknownError;

  /// No description provided for @recordingNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity in progress'**
  String get recordingNotificationTitle;

  /// No description provided for @recordingNotificationText.
  ///
  /// In en, this message translates to:
  /// **'Glaziovi is recording your location.'**
  String get recordingNotificationText;

  /// Distance label with unit
  ///
  /// In en, this message translates to:
  /// **'Distance ({unit})'**
  String distanceWithUnitHint(String unit);

  /// Average speed with unit
  ///
  /// In en, this message translates to:
  /// **'AVG Speed ({unit})'**
  String avgSpeedWithUnitHint(String unit);

  /// No description provided for @activitySelectSport.
  ///
  /// In en, this message translates to:
  /// **'Select sport'**
  String get activitySelectSport;

  /// No description provided for @activityRecorderDeleteHint.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to abandon the current activity?'**
  String get activityRecorderDeleteHint;

  /// No description provided for @activityRecorderAbandonTitle.
  ///
  /// In en, this message translates to:
  /// **'Abandon activity?'**
  String get activityRecorderAbandonTitle;

  /// No description provided for @activityRecorderAbandonAction.
  ///
  /// In en, this message translates to:
  /// **'Abandon'**
  String get activityRecorderAbandonAction;

  /// No description provided for @cancelHint.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelHint;

  /// No description provided for @activityTypeCycling.
  ///
  /// In en, this message translates to:
  /// **'Cycling'**
  String get activityTypeCycling;

  /// No description provided for @activityTypeGeneric.
  ///
  /// In en, this message translates to:
  /// **'Other sports'**
  String get activityTypeGeneric;

  /// No description provided for @activityTypeFitnessEquipment.
  ///
  /// In en, this message translates to:
  /// **'Fitness equipment'**
  String get activityTypeFitnessEquipment;

  /// No description provided for @activitySubTypeTreadmill.
  ///
  /// In en, this message translates to:
  /// **'Treadmill'**
  String get activitySubTypeTreadmill;

  /// No description provided for @activitySubTypeIndoorWalking.
  ///
  /// In en, this message translates to:
  /// **'Indoor walking'**
  String get activitySubTypeIndoorWalking;

  /// No description provided for @activitySubTypeSpeedWalking.
  ///
  /// In en, this message translates to:
  /// **'Speed walking'**
  String get activitySubTypeSpeedWalking;

  /// No description provided for @activitySubTypeSpin.
  ///
  /// In en, this message translates to:
  /// **'Spinning'**
  String get activitySubTypeSpin;

  /// No description provided for @activitySubTypeIndoorCycling.
  ///
  /// In en, this message translates to:
  /// **'Indoor cycling'**
  String get activitySubTypeIndoorCycling;

  /// No description provided for @activityTypeRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get activityTypeRunning;

  /// No description provided for @activityTypeWalking.
  ///
  /// In en, this message translates to:
  /// **'Walking'**
  String get activityTypeWalking;

  /// No description provided for @activitySubTypeGeneric.
  ///
  /// In en, this message translates to:
  /// **'Traditional'**
  String get activitySubTypeGeneric;

  /// No description provided for @activitySubTypeRunStreet.
  ///
  /// In en, this message translates to:
  /// **'Street running'**
  String get activitySubTypeRunStreet;

  /// No description provided for @activitySubTypeRunTrail.
  ///
  /// In en, this message translates to:
  /// **'Trail running'**
  String get activitySubTypeRunTrail;

  /// No description provided for @activitySubTypeRunTrack.
  ///
  /// In en, this message translates to:
  /// **'Track running'**
  String get activitySubTypeRunTrack;

  /// No description provided for @activitySubTypeWalkCasual.
  ///
  /// In en, this message translates to:
  /// **'Casual walking'**
  String get activitySubTypeWalkCasual;

  /// No description provided for @activitySubTypeCycleRoad.
  ///
  /// In en, this message translates to:
  /// **'Road'**
  String get activitySubTypeCycleRoad;

  /// No description provided for @activitySubTypeCycleMountain.
  ///
  /// In en, this message translates to:
  /// **'Mountain bike'**
  String get activitySubTypeCycleMountain;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
