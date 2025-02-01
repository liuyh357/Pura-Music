// ignore_for_file: library_private_types_in_public_api


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

enum PuraProgressFormat { percentage, decimal }

class PuraProgressBar extends StatefulWidget {
  final double width; // 进度条的宽度
  final double height; // 进度条的高度
  final double maxProgress; // 最大进度值（音乐时长）
  final bool showPercentage; // 是否显示百分比
  final PuraProgressFormat progressFormat; // 进度格式（百分比或小数）
  final Function(double)? onDragEnd; // 拖动结束后的回调函数
  final double progress; // 初始进度
  const PuraProgressBar({
    super.key,
    required this.width,
    required this.height,
    required this.maxProgress,
    this.showPercentage = true, // 默认为显示百分比
    this.progressFormat = PuraProgressFormat.percentage, // 默认显示百分比
    this.onDragEnd,
    this.progress = 0, // 默认进度为0
  });

  @override
  _PuraProgressBarState createState() => _PuraProgressBarState();
}

class _PuraProgressBarState extends State<PuraProgressBar> {
  late double _progress; // 初始化进度
  bool _isHovering = false; // 是否鼠标悬停
  bool _isDragging = false; // 是否正在拖动
  double _dragPosition = 0.0; // 拖动位置

  @override
  void initState() {
    super.initState();
    // 使用传入的初始进度值
    _progress = widget.progress.clamp(0.0, widget.maxProgress);
  }

  String get displayProgress {
    // 根据进度格式选择显示百分比或小数
    if (widget.progressFormat == PuraProgressFormat.percentage) {
      return '${((_progress / widget.maxProgress) * 100).toStringAsFixed(0)}%';
    } else {
      return _progress.toStringAsFixed(1); // 直接返回实际的进度值（保留1位小数）
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isDragging) {
      _progress = widget.progress.clamp(0.0, widget.maxProgress);
    }
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _isHovering = true;
        });
      },
      onExit: (_) {
        setState(() {
          _isHovering = false;
        });
      },
      child: GestureDetector(
        onHorizontalDragUpdate: (details) {
          setState(() {
            _isDragging = true;
            _dragPosition = details.localPosition.dx;
            // 根据最大进度计算当前进度值，确保不超过范围
            _progress = (_dragPosition / widget.width * widget.maxProgress)
                .clamp(0.0, widget.maxProgress);
          });
        },
        onHorizontalDragEnd: (details) {
          setState(() {
            _isDragging = false;
            _dragPosition = 0.0; // 重置拖动位置
          });

          // 如果提供了 onDragEnd 回调函数，调用它并传递当前的进度
          if (widget.onDragEnd != null) {
            setState(() {
              widget.onDragEnd!(_progress);
            });
          }
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedScale(
              scale: _isHovering || _isDragging
                  ? (widget.width + 10) / widget.width
                  : 1.0, // 鼠标悬停或拖动时进度条放大
              duration: const Duration(milliseconds: 170), // 设置动画时长
              curve: Curves.easeInOut, // 设置动画曲线
              child: CustomPaint(
                size: Size(widget.width, widget.height), // 使用自定义宽高
                painter: PuraProgressBarPainter(_progress, widget.maxProgress),
              ),
            ),
            // 显示进度，只有在拖动时才显示
            if (_isDragging)
              Positioned(
                child: Text(
                  displayProgress, // 显示百分比或小数
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class PuraProgressBarPainter extends CustomPainter {
  final double progress;
  double maxProgress;

  PuraProgressBarPainter(this.progress, this.maxProgress);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.white.withOpacity(0.3) // 背景透明白色
      ..style = PaintingStyle.fill;

    Paint progressPaint = Paint()
      ..color = Colors.white.withOpacity(0.7) // 进度透明白色
      ..style = PaintingStyle.fill;

    // 圆角半径
    const radius = Radius.circular(5);

    // 裁切区域：绘制圆角矩形背景
    Rect outerRect = Rect.fromLTWH(0, 0, size.width, size.height);
    RRect outerRRect = RRect.fromRectAndRadius(outerRect, radius);
    canvas.clipRRect(outerRRect); // 裁切进度条区域

    // 绘制进度条背景
    canvas.drawRRect(outerRRect, paint);
    if(maxProgress == 0){
      maxProgress = 1;
    }
    // 根据进度绘制进度条
    double progressWidth = size.width * (progress / maxProgress);
    Rect progressRect = Rect.fromLTWH(0, 0, progressWidth, size.height);
    RRect progressRRect = RRect.fromRectAndRadius(progressRect, radius);
    canvas.drawRRect(progressRRect, progressPaint); // 绘制进度条
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
