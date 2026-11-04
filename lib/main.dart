import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'features/timer/application/timer_controller.dart';
import 'features/timer/data/timer_repository.dart';
import 'services/timer_notifications.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _registerFontLicenses();
  final notifications = LocalTimerNotifications();
  await notifications.initialize();
  final controller = TimerController(
    repository: SharedPreferencesTimerRepository(),
    notifications: notifications,
  );
  await controller.initialize();
  runApp(RanadoroApp(controller: controller));
}

void _registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    final caveat = await rootBundle.loadString(
      'assets/licenses/OFL-Caveat.txt',
    );
    yield LicenseEntryWithLineBreaks(<String>['Caveat'], caveat);
    final inter = await rootBundle.loadString('assets/licenses/OFL-Inter.txt');
    yield LicenseEntryWithLineBreaks(<String>['Inter'], inter);
  });
}
