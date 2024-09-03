import 'package:face_auth_flutter/face_auth/menu_page.dart';
import 'package:face_auth_flutter/utils/local_db.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'utils/utils.dart';

Future main() async {
  //

  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  await HiveBoxes.initialize();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  FlutterError.onError =
      (FlutterErrorDetails flutterErrorDetails, {bool fatal = false}) {
    //

    pe("Error in at flutter error  => ", flutterErrorDetails);

    pe("Error in at flutter Exception => ", flutterErrorDetails.exception);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    //

    pe("Error catch at dispatcher", error.toString());

    pe(error, stack);

    return true;
  };

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => const MaterialApp(
        debugShowCheckedModeBanner: false,
        title: "Face Auth",
        home: LoginPage(),
      );
}
