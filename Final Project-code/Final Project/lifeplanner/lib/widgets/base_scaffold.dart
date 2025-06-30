import 'package:flutter/material.dart';
import 'offline_banner.dart';

class BaseScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget child;
  final Widget? bottomNavigationBar;

  /// Add this line:
  final Widget? floatingActionButton;

  const BaseScaffold({
    super.key,
    this.appBar,
    required this.child,
    this.bottomNavigationBar,
    this.floatingActionButton, // ← new parameter
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: Column(children: [const OfflineBanner(), Expanded(child: child)]),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton, // ← pass it through
    );
  }
}
