import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pura_music/data_controller.dart';
import 'package:pura_music/pura_page_all_songs.dart';
import 'package:pura_music/settings.dart';

class PuraMainPageView extends StatefulWidget {
  const PuraMainPageView({Key? key}) : super(key: key);

  @override
  _PuraMainPageViewState createState() => _PuraMainPageViewState();
}

class _PuraMainPageViewState extends State<PuraMainPageView> {
  @override
  Widget build(BuildContext context) {
    return Selector<DataController, int>(
      selector: (context, dataController) => dataController.indexOfPuraNavigationRail,
      builder: (context, currentIndex,child){
        // pageController.jumpToPage(currentIndex);
        return Expanded(
            child: PageView(
              clipBehavior: Clip.antiAlias,
              controller: Provider.of<DataController>(context).mainPageController,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                PuraPageAllSongs(),
                Settings(),
              ],
            ));
      },
    );
  }
}
