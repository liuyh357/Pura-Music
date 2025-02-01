// import 'dart:math';

import 'package:flutter/material.dart';

class NoAnimationPageRoute<T> extends MaterialPageRoute<T> {
  NoAnimationPageRoute({required super.builder, super.settings});

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    // 禁用动画
    return child;
  }
}

