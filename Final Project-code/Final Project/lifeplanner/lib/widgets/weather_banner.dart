import 'package:flutter/material.dart';

class WeatherBanner extends StatelessWidget {
  final double tempC;
  final String description;
  final String iconUrl;
  final String quote;
  final double feelsLikeC;

  const WeatherBanner({
    required this.tempC,
    required this.feelsLikeC,
    required this.description,
    required this.iconUrl,
    required this.quote,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    const borderC = Color(0xFFFFCD7D);
    const bgC = Color(0xFF7A72F2); // tweak to your purple

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
          // Title
          Text(
            'Weather',
            style: TextStyle(fontSize: w * 0.06, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          // Weather Info: Temp and Feels Like
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '${tempC.toStringAsFixed(0)}°C',
                style: TextStyle(
                  fontSize: w * 0.06,
                  fontWeight: FontWeight.bold,
                  color: Colors.black, // Temp color changed to black
                ),
              ),
              Text(
                'Feels like ${feelsLikeC.toStringAsFixed(0)}°C',
                style: TextStyle(
                  fontSize: w * 0.04,
                  color: Colors.white, // Feels like text color set to white
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Description Text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: w * 0.045,
                color: Colors.black, // Description color changed to black
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Icon below description
          Image.network(
            iconUrl,
            width: w * 0.12, // Icon size adjusted for better appearance
            height: w * 0.12,
            fit: BoxFit.cover,
          ),
          const SizedBox(height: 8),
          // Motivational Quote
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Text(
              quote,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: w * 0.04,
                fontStyle: FontStyle.italic,
                color: Colors.black, // Quote color changed to black
              ),
            ),
          ),
        ],
      ),
    );
  }
}
