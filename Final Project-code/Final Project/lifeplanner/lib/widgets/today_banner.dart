import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TodayBanner extends StatefulWidget {
  const TodayBanner({super.key});

  @override
  State<TodayBanner> createState() => _TodayBannerState();
}

class _TodayBannerState extends State<TodayBanner> {
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    // Tick every minute on the minute
    final nextTick = DateTime(
      _now.year,
      _now.month,
      _now.day,
      _now.hour,
      _now.minute + 1,
    ).difference(_now);
    // Start first tick to align to top of minute
    _timer = Timer(nextTick, _onTick);
  }

  void _onTick() {
    setState(() => _now = DateTime.now());
    // Schedule subsequent ticks every minute
    _timer = Timer(const Duration(minutes: 1), _onTick);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final timePart = DateFormat('h:mm a').format(_now);
    final datePart = DateFormat('EEEE, MMMM d, yyyy').format(_now);
    final fullLabel = '$timePart $datePart';
    const bgColor = Color(0xFFFFEDB5);
    const borderC = Color(0xFFFFCD7D);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.symmetric(
        vertical: screenWidth * 0.04,
        horizontal: screenWidth * 0.05,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderC, width: 2),
      ),
      child: Column(
        children: [
          Text(
            'Today:',
            style: TextStyle(
              fontSize: screenWidth * 0.06,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            fullLabel,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: screenWidth * 0.045),
          ),
        ],
      ),
    );
  }
}
