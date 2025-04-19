import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:pura_music/media_controller.dart';
import 'package:pura_music/pura_page_all_songs.dart';
import 'package:pura_music/settings.dart';

class PuraMainPageView extends StatefulWidget {
  const PuraMainPageView({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _PuraMainPageViewState createState() => _PuraMainPageViewState();
}

class _PuraMainPageViewState extends State<PuraMainPageView> {
  @override
  Widget build(BuildContext context) {
    return Expanded(
            child: PageView(
              clipBehavior: Clip.antiAlias,
              controller: PageController(),
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                PuraPageAllSongs(),
                Settings(),
              ],
            ));
  }
}
