import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pura_music/pura_app_bar.dart';
import 'package:pura_music/pura_main_page_view.dart';
import 'package:pura_music/pura_navigation_rail.dart';
import 'package:window_manager/window_manager.dart';
import 'data_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 必须加上这一行。
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(800, 600),
    minimumSize: Size(800, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
  runApp(ChangeNotifierProvider(
      create: (context) => DataController(), child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Pura Music',
      home: MyHomePage(title: 'Pura Music'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    // var screenSize = MediaQuery.of(context).size;
    return Scaffold(
      appBar: PuraAppBar(title: widget.title),
      body: Center(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PuraNavigationRail(),
            const VerticalDivider(
              width: 1,
              color: Color.fromRGBO(230, 230, 230, 1.0),
            ),
            Text(Provider.of<DataController>(context)
                .indexOfPuraNavigationRail
                .toString()),
            const PuraMainPageView(),
          ],
        ),
      ),
    );
  }
}
