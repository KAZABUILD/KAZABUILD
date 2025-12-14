import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;

import 'restart_widget.dart';

/// Wraps the entire app and listens for a downward swipe/overscroll gesture
/// at the top of any scrollable. Once the drag passes a threshold, it performs
/// a hard reload:
/// - Web: reloads the current page.
/// - Mobile/Desktop: rebuilds the whole widget tree to restart providers.
class GlobalSwipeReload extends StatefulWidget {
  const GlobalSwipeReload({super.key, required this.child});

  final Widget child;

  @override
  State<GlobalSwipeReload> createState() => _GlobalSwipeReloadState();
}

class _GlobalSwipeReloadState extends State<GlobalSwipeReload> {
  static const double _triggerOffset = 140.0;
  double _dragOffset = 0;
  bool _isReloading = false;

  void _resetDrag() => _dragOffset = 0;

  Future<void> _triggerReload() async {
    if (_isReloading) return;

    setState(() {
      _isReloading = true;
    });

    try {
      if (kIsWeb) {
        html.window.location.reload();
        return;
      }
      RestartWidget.restart(context);
    } finally {
      if (mounted) {
        setState(() {
          _isReloading = false;
        });
      }
    }
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (_isReloading) return false;

    final atTop = notification.metrics.pixels <= 0;
    if (!atTop) {
      _resetDrag();
      return false;
    }

    if (notification is OverscrollNotification && notification.overscroll < 0) {
      _dragOffset += -notification.overscroll;
    } else if (notification is ScrollUpdateNotification) {
      final dragDelta = notification.dragDetails?.delta.dy ?? 0;
      if (dragDelta > 0) {
        _dragOffset += dragDelta;
      } else if (dragDelta < 0) {
        _resetDrag();
      }
    } else if (notification is ScrollEndNotification) {
      _resetDrag();
    }

    if (_dragOffset >= _triggerOffset) {
      _resetDrag();
      _triggerReload();
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: _handleScrollNotification,
          child: widget.child,
        ),
        if (_isReloading)
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 0,
            right: 0,
            child: const _ReloadBadge(),
          ),
      ],
    );
  }
}

class _ReloadBadge extends StatelessWidget {
  const _ReloadBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text('Reloading...'),
          ],
        ),
      ),
    );
  }
}


