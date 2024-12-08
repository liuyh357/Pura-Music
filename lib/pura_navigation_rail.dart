import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pura_music/data_controller.dart';
import 'package:chinese_font_library/chinese_font_library.dart';
class PuraNavigationRail extends StatefulWidget {
  const PuraNavigationRail({Key? key}) : super(key: key);

  @override
  _PuraNavigationRailState createState() => _PuraNavigationRailState();
}

class _PuraNavigationRailState extends State<PuraNavigationRail> {
  @override
  Widget build(BuildContext context) {
    return Selector<DataController, int>(
      selector: (context, dataController) =>
          dataController.indexOfPuraNavigationRail,
      builder: (context, currentIndex, child) {
        return NavigationRail(
          labelType: NavigationRailLabelType.selected,
          groupAlignment: 0.0,
          // indicatorShape: const RoundedRectangleBorder(),
          selectedIconTheme: const IconThemeData(color: Colors.white),
          indicatorColor: Colors.blue,
          // elevation: 13.0,
          destinations: <NavigationRailDestination>[
            NavigationRailDestination(
                icon: const Icon(Icons.queue_music_rounded),
                selectedIcon: const Icon(Icons.queue_music_rounded),
                label: Text('全部歌曲', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.0).useSystemChineseFont(),)),
            NavigationRailDestination(
                icon: const Icon(Icons.star_border_outlined),
                selectedIcon: const Icon(Icons.star),
                label: Text('收藏', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.0).useSystemChineseFont(),)),
          ],
          selectedIndex: currentIndex,
          onDestinationSelected: (int index) {
            Provider.of<DataController>(context, listen: false)
                .changeIndexOfPuraNavigationRail(index);
          },
        );
      },
    );
  }
}
