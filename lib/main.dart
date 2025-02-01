import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pura_music/pura_main_app_bar.dart';
import 'package:pura_music/pura_main_bottom_bar.dart';
import 'package:pura_music/pura_main_page_view.dart';
import 'package:pura_music/pura_navigation_rail.dart';
import 'package:pura_music/pura_page_play.dart';
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

  // 设置 ImageCache 的最大数量和大小
  PaintingBinding.instance.imageCache.maximumSize = 300; // 最大图像条目
  PaintingBinding.instance.imageCache.maximumSizeBytes =
      100 * 1024 * 1024; // 最大字节数（100MB）
  runApp(ChangeNotifierProvider(
      create: (context) => DataController.getInstance(), child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // 初始路由
      initialRoute: '/',
      // 显式设置路由
      routes: {
        '/': (context) => const MyHomePage(title: 'Pura Music'),
        '/play': (context) => const PuraPagePlay(),
      },
      title: 'Pura Music',
      // home: const MyHomePage(title: 'Pura Music'),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: TextTheme(
          displayLarge: const TextStyle().useSystemChineseFont(),
          displayMedium: const TextStyle().useSystemChineseFont(),
          displaySmall: const TextStyle().useSystemChineseFont(),
          headlineLarge: const TextStyle().useSystemChineseFont(),
          headlineMedium: const TextStyle().useSystemChineseFont(),
          headlineSmall: const TextStyle().useSystemChineseFont(),
          titleLarge: const TextStyle().useSystemChineseFont(),
          titleMedium: const TextStyle().useSystemChineseFont(),
          titleSmall: const TextStyle().useSystemChineseFont(),
          bodyLarge: const TextStyle().useSystemChineseFont(),
          bodyMedium: const TextStyle().useSystemChineseFont(),
          bodySmall: const TextStyle().useSystemChineseFont(),
          labelLarge: const TextStyle().useSystemChineseFont(),
          labelMedium: const TextStyle().useSystemChineseFont(),
          labelSmall: const TextStyle().useSystemChineseFont(),

        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            textStyle: const TextStyle().useSystemChineseFont(),
          )
        )
      ),
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
    return DecoratedBox(
      decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [
        Color.fromARGB(255, 236, 194, 194),
        Color.fromARGB(255, 238, 151, 145)
      ])),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PuraMainAppBar(title: widget.title),
        body: const Center(
          child: Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PuraNavigationRail(),
                  // VerticalDivider(
                  //   width: 1,
                  //   color: Color.fromRGBO(230, 230, 230, 1.0),
                  // ),
                  // Text(Provider.of<DataController>(context)
                  //     .indexOfPuraNavigationRail
                  //     .toString()),
                  PuraMainPageView(),
                ],
              ),
              Align(
                  alignment: Alignment.bottomCenter,
                  child: PuraMainBottomBar()),
            ],
          ),
        ),
        // bottomNavigationBar: PuraMainBottomBar(),
      ),
    );
  }
}
