import 'package:window_manager/window_manager.dart';
import 'package:flutter/material.dart';
class PuraAppBar extends StatefulWidget implements PreferredSizeWidget {
  const PuraAppBar({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _PuraAppBarState createState() => _PuraAppBarState();

  @override
  // TODO: implement preferredSize
  Size get preferredSize => const Size.fromHeight(50.0);
}

class _PuraAppBarState extends State<PuraAppBar>  with WindowListener{
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
    // TODO: implement onWindowMaximize
    super.onWindowMaximize();
    print("onWindowMaximize");
    setState(() {
      isMaximized = true;
    });
  }
  @override
  void onWindowUnmaximize() {
    // TODO: implement onWindowUnmaximize
    super.onWindowUnmaximize();
    print("onWindowUnmaximize");
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
          backgroundColor: Colors.blue.shade50,
          title: Text(widget.title),
          actions: [
            // Text('$isMaximized'),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              tooltip: '最小化',
              onPressed: () {
                windowManager.minimize();
              },
            ),
            IconButton(
              icon: Icon(isMaximized? Icons.radio_button_checked : Icons.brightness_1),
              tooltip: '最大化/还原',
              onPressed: () async {
                if (isMaximized) {
                  windowManager.restore();
                } else {
                  windowManager.maximize();
                }
              },
            ),
            IconButton(
              // icon: const Icon(Icons.motion_photos_off),
              icon: const Icon(Icons.highlight_off),
              tooltip: '退出程序',
              onPressed: () {
                windowManager.close();
              },
            ),
          ],
        ),
      ),
    );
  }
}
