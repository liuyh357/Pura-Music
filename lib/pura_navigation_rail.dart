import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pura_music/data_controller.dart';

class PuraNavigationRail extends StatefulWidget {
  const PuraNavigationRail({super.key});

  @override
  _PuraNavigationRailState createState() => _PuraNavigationRailState();
}

class _PuraNavigationRailState extends State<PuraNavigationRail> {
  int indexOfPuraNavigationRail = 0;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Material(
        color: Colors.transparent,
        shape: const ContinuousRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(25.0))),
        clipBehavior: Clip.antiAlias,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: Color.fromRGBO(110, 110, 110, 0.498),
            // borderRadius: BorderRadius.all(Radius.circular(10.0)),
          ),
          child: NavigationRail(
            backgroundColor: const Color.fromRGBO(239, 247, 251, 0),
            labelType: NavigationRailLabelType.selected,
            groupAlignment: 0.0,
            indicatorShape: const ContinuousRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10.0))),
            selectedIconTheme: const IconThemeData(color: Colors.white),
            indicatorColor: Colors.blue,
            // elevation: 13.0,
            destinations: const <NavigationRailDestination>[
              NavigationRailDestination(
                  icon: Icon(Icons.queue_music_rounded),
                  selectedIcon: Icon(Icons.queue_music_rounded),
                  label: Text(
                    '全部歌曲',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.0,
                        color: Color.fromARGB(255, 243, 243, 243)),
                  )),
              NavigationRailDestination(
                  icon: Icon(Icons.star_border_outlined),
                  selectedIcon: Icon(Icons.star),
                  label: Text(
                    '收藏',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.0,
                        color: Color.fromARGB(255, 243, 243, 243)),
                  )),
            ],
            selectedIndex: indexOfPuraNavigationRail,
            onDestinationSelected: (int index) {
              setState(() {
                indexOfPuraNavigationRail = index;
              });
            },
          ),
        ),
      ),
    );
  }
}
