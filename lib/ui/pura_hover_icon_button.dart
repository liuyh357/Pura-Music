
import 'package:flutter/material.dart';

class PuraHoverIconButton extends StatefulWidget {
  final Widget icon; // 图标
  final VoidCallback onPressed; // 点击回调
  final double size; // 图标大小

  const PuraHoverIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 24.0, // 默认图标大小为 24.0
  });

  @override
  _PuraHoverIconButtonState createState() => _PuraHoverIconButtonState();
}

class _PuraHoverIconButtonState extends State<PuraHoverIconButton> {
  double _scale = 1.0; // 图标的初始缩放比例

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        // 鼠标悬停时，放大图标
        setState(() {
          _scale = 1.2; // 放大20%
        });
      },
      onExit: (_) {
        // 鼠标离开时，恢复原大小
        setState(() {
          _scale = 1.0; // 恢复原大小
        });
      },
      child: AnimatedScale(
        scale: _scale, // 使用 _scale 来控制缩放
        duration: const Duration(milliseconds: 100), // 设置动画时长
        curve: Curves.linear, // 设置动画曲线
        filterQuality: FilterQuality.high, // 设置图片质量
        child: IconButton(
          icon: widget.icon,
          iconSize: widget.size, // 图标的大小
          onPressed: widget.onPressed, // 按钮点击回调
        ),
      ),
    );
  }
}
