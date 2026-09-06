import 'package:glaziovi/activity/activity_data.dart';
import 'package:glaziovi/activity/data-access/activity_dao.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_page_view_model.g.dart';

@riverpod
class HomePageViewModel extends _$HomePageViewModel {
  @override
  Future<List<ActivityData>> build() async {
    final activityDao = await ref.read(activityDAOProvider.future);

    return await activityDao.listFinished();
  }
}
