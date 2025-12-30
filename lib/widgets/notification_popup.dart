import 'package:flutter/material.dart';
import '../config/themes/app_theme.dart';
import 'glass_container.dart';

class NotificationPopup {
  static void show(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierColor: Colors.black26,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) => GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            Positioned(
              top: 80,
              right: AppTheme.spacingM,
              child: GestureDetector(
                onTap: () {}, // Prevent tap from closing
                child: GlassContainer(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  child: Material(
                    type: MaterialType.transparency,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 280,
                        maxHeight: 300,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Notifications',
                                style: AppTheme.headingSmall,
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 20),
                                onPressed: () => Navigator.of(context).pop(),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spacingM),
                          Flexible(
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.notifications_off_outlined,
                                    size: 48,
                                    color: AppTheme.textMuted,
                                  ),
                                  const SizedBox(height: AppTheme.spacingS),
                                  Text(
                                    'No notifications yet',
                                    style: AppTheme.bodyMedium.copyWith(
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                ],
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
          ],
        ),
      ),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.elasticOut,
          reverseCurve: Curves.easeInBack,
        );

        return ScaleTransition(
          scale: curvedAnimation,
          alignment: Alignment.topRight,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }
}
