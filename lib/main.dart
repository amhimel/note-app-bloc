import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:note_app_bloc/injection_container.dart';
import 'app.dart';


// main() এ ৩টি কাজ:
//   1. Flutter engine initialize করো
//   2. Dependencies setup করো (Hive + get_it)
//   3. App চালু করো
//
// async main() কেন?
//   initDependencies() async কারণ:
//     → Hive.initFlutter() async
//     → Hive.openBox()     async
//   এগুলো শেষ না হলে App চালু করা যাবে না।

void main() async {
  // Flutter engine ও native layer ready করো।
  // async main() এ এটা সবার আগে call করতে হয়।
  WidgetsFlutterBinding.ensureInitialized();

  // Portrait mode lock (optional)
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Hive initialize + get_it এ সব dependencies register করো
  await initDependencies();

  // App চালু করো
  runApp(const App());
}
