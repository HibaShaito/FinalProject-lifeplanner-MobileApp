import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class NetworkStatusNotifier extends ChangeNotifier {
  bool _isOnline = true;

  bool get isOnline => _isOnline;

  NetworkStatusNotifier() {
    _init();
  }

  void _init() {
    Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> resultList,
    ) {
      final isConnected =
          resultList.isNotEmpty &&
          !resultList.contains(ConnectivityResult.none);
      if (isConnected != _isOnline) {
        _isOnline = isConnected;
        notifyListeners();
      }
    });
  }
}
