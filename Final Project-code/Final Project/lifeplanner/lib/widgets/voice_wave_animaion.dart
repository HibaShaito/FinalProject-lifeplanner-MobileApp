import 'package:flutter/material.dart';

class VoiceWaveAnimation extends StatefulWidget {
  const VoiceWaveAnimation({super.key});

  @override
  State<VoiceWaveAnimation> createState() => _VoiceWaveAnimationState();
}

class _VoiceWaveAnimationState extends State<VoiceWaveAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _waves;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    // Create staggered animations for waves
    _waves = List.generate(3, (i) {
      final start = i * 0.2;
      final end = start + 0.6;
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeInOut),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 30,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(painter: _WavePainter(_waves));
        },
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final List<Animation<double>> waves;
  _WavePainter(this.waves) : super(repaint: waves.first);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.blueAccent.withValues(alpha: 0.7)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;

    final centerY = size.height / 2;
    final widthPerWave = size.width / 6;

    for (int i = 0; i < waves.length; i++) {
      final animValue = waves[i].value;
      final x = widthPerWave * (i * 2 + 1);

      final waveHeight = 10 * animValue; // max amplitude = 10
      final path = Path();
      path.moveTo(x, centerY + waveHeight);
      path.lineTo(x, centerY - waveHeight);

      paint.color = Colors.blueAccent.withValues(alpha: 0.3 + 0.7 * animValue);
      paint.strokeWidth = 2 + 2 * animValue;

      canvas.drawLine(
        Offset(x, centerY + waveHeight),
        Offset(x, centerY - waveHeight),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) => true;
}
