import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WeatherSettingsPage extends StatefulWidget {
  const WeatherSettingsPage({super.key});

  @override
  State<WeatherSettingsPage> createState() => _WeatherSettingsPageState();
}

class _WeatherSettingsPageState extends State<WeatherSettingsPage> {
  String? _countryName;
  String? _cityName;
  bool _loading = false;
  String? _error;

  Future<void> _saveLocation({
    double? lat,
    double? lon,
    String? country,
    String? city,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final prefsRef = FirebaseFirestore.instance
        .collection('Users')
        .doc(uid)
        .collection('settings')
        .doc('preferences');

    await prefsRef.set({
      'weatherLocation': {
        'lat': lat,
        'lon': lon,
        'country': country,
        'city': city,
      },
    }, SetOptions(merge: true));
  }

  Future<void> _useDeviceLocation() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        throw Exception('Location permission denied');
      }

      final pos = await Geolocator.getCurrentPosition();
      final placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      if (placemarks.isEmpty) throw Exception('No address found');
      final pm = placemarks.first;

      setState(() {
        _countryName = pm.country;
        _cityName = pm.locality ?? pm.subAdministrativeArea;
      });

      await _saveLocation(
        lat: pos.latitude,
        lon: pos.longitude,
        country: _countryName,
        city: _cityName,
      );

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _error = 'Could not get location: ${e.toString()}';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather Location'),
        backgroundColor: const Color(0xFFFFCD7D),
        centerTitle: true,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.wb_sunny, size: 80, color: Color(0xFFFFCD7D)),
              const SizedBox(height: 16),
              const Text(
                'Get personalized weather updates using your current location.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              Card(
                elevation: 3,
                color: const Color(0xFFFFF3DD),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.my_location),
                        label: const Text('Use My Current Location'),
                        onPressed: _loading ? null : _useDeviceLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFCD7D),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 20,
                          ),
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                      ),
                      if (_loading) ...[
                        const SizedBox(height: 12),
                        const CircularProgressIndicator(),
                        const SizedBox(height: 8),
                        const Text(
                          'Fetching location...',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              if (_cityName != null && _countryName != null)
                Column(
                  children: [
                    const Text(
                      'Selected Location',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$_cityName, $_countryName',
                      style: const TextStyle(fontSize: 15),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
