import 'package:flutter/material.dart';
import 'glass_container.dart';
import '../config/themes/app_theme.dart';

class BouncingGlassButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;

  const BouncingGlassButton({
    super.key,
    required this.child,
    this.onTap,
    this.backgroundColor,
    this.borderRadius,
    this.padding,
    this.width,
    this.height,
  });

  @override
  State<BouncingGlassButton> createState() => _BouncingGlassButtonState();
}

class _BouncingGlassButtonState extends State<BouncingGlassButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    if (widget.onTap != null) {
      widget.onTap!();
    }
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: GlassContainer(
              width: widget.width,
              height: widget.height,
              padding:
                  widget.padding ?? const EdgeInsets.all(AppTheme.spacingM),
              borderRadius: widget.borderRadius ?? AppTheme.radiusLarge,
              backgroundColor: widget.backgroundColor,
              // We handle tap in GestureDetector above, so pass null here
              onTap: null,
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}
