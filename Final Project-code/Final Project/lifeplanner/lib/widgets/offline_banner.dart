import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lifeplanner/utils/network_status_service.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final isOnline = context.watch<NetworkStatusNotifier>().isOnline;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: isOnline ? 0 : 30,
      color: Colors.red,
      child: const Center(
        child: Text(
          'No internet connection',
          style: TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }
}
