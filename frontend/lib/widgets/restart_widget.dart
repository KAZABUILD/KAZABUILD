import 'package:flutter/widgets.dart';

/// Simple helper that rebuilds the entire widget tree, effectively restarting
/// the app without killing the process.
class RestartWidget extends StatefulWidget {
  const RestartWidget({super.key, required this.child});

  final Widget child;

  /// Call this to trigger a full rebuild of the app.
  static void restart(BuildContext context) {
    final state = context.findAncestorStateOfType<_RestartWidgetState>();
    state?._restart();
  }

  @override
  State<RestartWidget> createState() => _RestartWidgetState();
}

class _RestartWidgetState extends State<RestartWidget> {
  Key _restartKey = UniqueKey();

  void _restart() {
    setState(() {
      _restartKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: _restartKey,
      child: widget.child,
    );
  }
}


