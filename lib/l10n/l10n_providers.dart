import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:glaziovi/l10n/app_localizations.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'l10n_providers.g.dart';

@riverpod
class AppLocale extends _$AppLocale {
  @override
  Locale build() {
    return basicLocaleListResolution(
      PlatformDispatcher.instance.locales,
      AppLocalizations.supportedLocales,
    );
  }

  void change(Locale locale) => state = locale;
}

@riverpod
AppLocalizations appLocalizations(Ref ref) {
  return lookupAppLocalizations(ref.watch(appLocaleProvider));
}
