import 'package:flutter/material.dart';
import 'package:glaziovi/activity/activity_sport.dart';
import 'package:glaziovi/activity/activity_sport_type.dart';
import 'package:glaziovi/activity/activity_sub_sport_type.dart';
import 'package:glaziovi/l10n/app_localizations.dart';

extension ActivitySportLabel on ActivitySportType {
  String label(AppLocalizations l10n) => switch (this) {
    ActivitySportType.generic => l10n.activityTypeGeneric,
    ActivitySportType.running => l10n.activityTypeRunning,
    ActivitySportType.cycling => l10n.activityTypeCycling,
    ActivitySportType.walking => l10n.activityTypeWalking,
    ActivitySportType.fitnessEquipment => l10n.activityTypeFitnessEquipment,
  };

  List<ActivitySubSportType> get subSports => switch (this) {
    ActivitySportType.running => const [
      ActivitySubSportType.generic,
      ActivitySubSportType.treadmill,
      ActivitySubSportType.street,
      ActivitySubSportType.trail,
      ActivitySubSportType.track,
    ],
    ActivitySportType.walking => const [
      ActivitySubSportType.generic,
      ActivitySubSportType.indoorWalking,
      ActivitySubSportType.casualWalking,
      ActivitySubSportType.speedWalking,
    ],
    ActivitySportType.cycling => const [
      ActivitySubSportType.generic,
      ActivitySubSportType.spin,
      ActivitySubSportType.indoorCycling,
      ActivitySubSportType.road,
      ActivitySubSportType.mountain,
    ],
    ActivitySportType.generic ||
    ActivitySportType.fitnessEquipment => const [ActivitySubSportType.generic],
  };
}

extension ActivitySubSportLabel on ActivitySubSportType {
  String label(AppLocalizations l10n) => switch (this) {
    ActivitySubSportType.generic => l10n.activitySubTypeGeneric,
    ActivitySubSportType.treadmill => l10n.activitySubTypeTreadmill,
    ActivitySubSportType.street => l10n.activitySubTypeRunStreet,
    ActivitySubSportType.trail => l10n.activitySubTypeRunTrail,
    ActivitySubSportType.track => l10n.activitySubTypeRunTrack,
    ActivitySubSportType.indoorWalking => l10n.activitySubTypeIndoorWalking,
    ActivitySubSportType.casualWalking => l10n.activitySubTypeWalkCasual,
    ActivitySubSportType.speedWalking => l10n.activitySubTypeSpeedWalking,
    ActivitySubSportType.spin => l10n.activitySubTypeSpin,
    ActivitySubSportType.indoorCycling => l10n.activitySubTypeIndoorCycling,
    ActivitySubSportType.road => l10n.activitySubTypeCycleRoad,
    ActivitySubSportType.mountain => l10n.activitySubTypeCycleMountain,
  };
}

class ActivitySportPicker extends StatelessWidget {
  const ActivitySportPicker({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              l10n.activitySelectSport,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final sport in ActivitySportType.values) ...[
                  Semantics(
                    header: true,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        sport.label(l10n),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                  for (final subSport in sport.subSports)
                    ListTile(
                      title: Text(subSport.label(l10n)),
                      onTap: () =>
                          Navigator.of(context)
                              .pop(ActivitySport.of(sport, subSport)),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
