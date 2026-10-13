import 'package:next_level/General/accessible.dart';
import 'package:next_level/Provider/user_provider.dart';
import 'package:next_level/Repository/user_repository.dart';
import 'package:next_level/Service/logging_service.dart';
import 'package:next_level/Service/level_progress_service.dart';
import 'package:get/get.dart';
import 'package:next_level/Widgets/Animations/level_up_dialog.dart';

class AppHelper {
  Future<void> addCreditByProgress(Duration? progress,
      {bool save = true}) async {
    if (progress == null) {
      LogService.error('⚠️ AppHelper: progress is null');
      return;
    }

    if (loginUser == null) {
      LogService.error('⚠️ AppHelper: loginUser is null');
      return;
    }

    // LogService.debug('💰 AppHelper: Adding progress: ${progress.inMinutes} minutes');
    // LogService.debug('💰 Before: credit=${loginUser!.userCredit}, progress=${loginUser!.creditProgress.inMinutes} minutes');

    loginUser!.creditProgress += progress;
    bool creditIncreased = false;

    // Handle positive progress
    while (loginUser!.creditProgress.inHours >= 1) {
      loginUser!.userCredit += 1;
      loginUser!.creditProgress -= const Duration(hours: 1);
      creditIncreased = true;
      LogService.debug(
          '💰 Credit increased! New credit: ${loginUser!.userCredit}');
    }

    // Handle negative progress
    while (loginUser!.creditProgress.inHours <= -1) {
      loginUser!.userCredit -= 1;
      loginUser!.creditProgress += const Duration(hours: 1);
      creditIncreased = true;
      LogService.debug(
          '💰 Credit decreased! New credit: ${loginUser!.userCredit}');
    }

    // LogService.debug('💰 After: credit=${loginUser!.userCredit}, progress=${loginUser!.creditProgress.inMinutes} minutes');

    // Only save if explicitly requested OR if credit amount changed (important event)
    if (save || creditIncreased) {
      await UserRepository().updateUser(loginUser!);
      // Sync with UserProvider to update UI immediately
      UserProvider().setUser(loginUser!);

      if (creditIncreased && Get.key.currentState != null) {
        final newLevel = await LevelProgressService().consumeLevelChange();
        if (newLevel != null) {
          Get.dialog(LevelUpDialog(newLevel: newLevel));
        }
      }
    }
  }
}
