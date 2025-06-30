import 'package:flutter/material.dart';

class WeatherDisabledBanner extends StatelessWidget {
  final String? message;

  const WeatherDisabledBanner({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    const borderC = Color(0xFFFFCD7D);
    const bgC = Color(0xFF7A72F2); // match WeatherBanner background

    final displayMessage =
        message ?? 'Want to see the weather?\nEnable it in Settings!';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.symmetric(vertical: w * 0.04, horizontal: w * 0.05),
      decoration: BoxDecoration(
        color: bgC,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderC, width: 2),
      ),
      child: Column(
        children: [
          Text(
            'Weather',
            style: TextStyle(
              fontSize: w * 0.06,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            displayMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: w * 0.04,
              color: Colors.white,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
