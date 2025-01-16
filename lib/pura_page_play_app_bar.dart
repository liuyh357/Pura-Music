import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class PuraPagePlayAppBar extends StatefulWidget implements PreferredSizeWidget {
  const PuraPagePlayAppBar({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _PuraPagePlayAppBarState createState() => _PuraPagePlayAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(50.0);
}

class _PuraPagePlayAppBarState extends State<PuraPagePlayAppBar>
    with WindowListener {
  bool isMaximized = false;
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowMaximize() {
    super.onWindowMaximize();
    // print("onWindowMaximize");
    setState(() {
      isMaximized = true;
    });
  }

  @override
  void onWindowUnmaximize() {
    super.onWindowUnmaximize();
    // print("onWindowUnmaximize");
    setState(() {
      isMaximized = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      // cursor: SystemMouseCursors.move,
      child: GestureDetector(
        onPanUpdate: (details) {
          windowManager.startDragging();
        },
        child: AppBar(
          // backgroundColor: Colors.blue.shade50,
          leading: IconButton(
            color: Colors.white,
            icon: const Icon(Icons.arrow_back),
            tooltip: '返回',
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          actions: [
            // Text('$isMaximized'),
            Hero(
              tag: 'appbar_minimize_button',
              child: IconButton(
                color: Colors.white,
                icon: const Icon(Icons.remove_circle_outline),
                tooltip: '最小化',
                onPressed: () {
                  windowManager.minimize();
                },
              ),
            ),

            Hero(
              tag: 'appbar_maximize_button',
              child: IconButton(
                color: Colors.white,
                icon: Icon(isMaximized
                    ? Icons.radio_button_checked
                    : Icons.brightness_1),
                tooltip: '最大化/还原',
                onPressed: () async {
                  if (isMaximized) {
                    windowManager.restore();
                  } else {
                    windowManager.maximize();
                  }
                },
              ),
            ),
            Hero(
              tag: 'appbar_close_button',
              child: IconButton(
                color: Colors.white,
                // icon: const Icon(Icons.motion_photos_off),
                icon: const Icon(Icons.highlight_off),
                tooltip: '退出程序',
                onPressed: () {
                  windowManager.close();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
