import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class AppToast {
  static void show(BuildContext context, String message, {dynamic icon}) {
    final overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        icon: icon ?? HugeIcons.strokeRoundedNotification02,
        onDismissed: () {
          if (overlayEntry.mounted) {
            overlayEntry.remove();
          }
        },
      ),
    );

    overlayState.insert(overlayEntry);
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final dynamic icon;
  final VoidCallback onDismissed;

  const _ToastWidget({
    required this.message,
    required this.icon,
    required this.onDismissed,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      reverseDuration: const Duration(milliseconds: 400),
    );
    
    _offsetAnimation = Tween<Offset>(begin: const Offset(0, -1.5), end: Offset.zero)
        .animate(CurvedAnimation(
          parent: _controller, 
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        ));
        
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(
          parent: _controller, 
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        ));

    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _controller.reverse().then((_) => widget.onDismissed());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 24,
      right: 24,
      child: SafeArea(
        child: RepaintBoundary(
          child: SlideTransition(
            position: _offsetAnimation,
            child: Material(
              color: Colors.transparent,
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF222222).withValues(alpha: 0.95), // Opaque dark grey
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        HugeIcon(
                          icon: widget.icon,
                          color: Colors.white,
                          size: 18,
                          strokeWidth: 2,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            widget.message,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
