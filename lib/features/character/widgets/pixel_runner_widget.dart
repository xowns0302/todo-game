import 'dart:async';
import 'package:flutter/material.dart';

const _frames = [
  'assets/images/test/run_1.png',
  'assets/images/test/run_2.png',
  'assets/images/test/run_3.png',
  'assets/images/test/run_4.png',
  'assets/images/test/run_5.png',
  'assets/images/test/run_6.png',
];

class PixelRunnerWidget extends StatefulWidget {
  final double size;
  final Duration frameDuration;

  const PixelRunnerWidget({
    super.key,
    this.size = 120,
    this.frameDuration = const Duration(milliseconds: 130),
  });

  @override
  State<PixelRunnerWidget> createState() => _PixelRunnerWidgetState();
}

class _PixelRunnerWidgetState extends State<PixelRunnerWidget> {
  int _frame = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.frameDuration, (_) {
      if (mounted) setState(() => _frame = (_frame + 1) % _frames.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _frames[_frame],
      width: widget.size,
      height: widget.size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.none, // 픽셀아트 선명하게
    );
  }
}
