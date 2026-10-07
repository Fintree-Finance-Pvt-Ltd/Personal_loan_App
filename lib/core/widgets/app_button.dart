import 'package:flutter/material.dart';
import '../../app/theme.dart';

/// Premium interactive CTA button widget adhering to [AppTheme].
/// Includes:
/// - Micro-scale touch feedback (0.982 on press)
/// - Integrated loading spinner
/// - Success state (morphs to checkmark)
/// - Disabled visual state
class AppButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSuccess;
  final bool isOutlined;
  final IconData? icon;
  final Color? iconColor;
  final double? width;
  final double height;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isSuccess = false,
    this.isOutlined = false,
    this.icon,
    this.iconColor,
    this.width,
    this.height = 50,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isPressed = false;

  bool get _isEnabled => widget.onPressed != null && !widget.isLoading;

  @override
  Widget build(BuildContext context) {
    final bool disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    Widget buttonBody = AnimatedScale(
      scale: (_isPressed && _isEnabled && !disableAnimations) ? 0.982 : 1.0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOutCubic,
      child: SizedBox(
        width: widget.width ?? double.infinity,
        height: widget.height,
        child: widget.isOutlined ? _buildOutlined(context) : _buildElevated(context),
      ),
    );

    return Listener(
      onPointerDown: (_) {
        if (_isEnabled) setState(() => _isPressed = true);
      },
      onPointerUp: (_) {
        if (_isEnabled) setState(() => _isPressed = false);
      },
      onPointerCancel: (_) {
        if (_isEnabled) setState(() => _isPressed = false);
      },
      child: buttonBody,
    );
  }

  Widget _buildElevated(BuildContext context) {
    Color bgColor = AppTheme.primaryTeal;
    if (widget.isSuccess) {
      bgColor = AppTheme.successGreen;
    } else if (!_isEnabled) {
      bgColor = AppTheme.borderLight;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: _isEnabled && !widget.isSuccess
            ? [
                BoxShadow(
                  color: AppTheme.primaryTeal.withValues(alpha: 0.22),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: _isEnabled ? widget.onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          disabledForegroundColor: AppTheme.textMuted,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: EdgeInsets.zero,
        ),
        child: _buildChild(context, Colors.white),
      ),
    );
  }

  Widget _buildOutlined(BuildContext context) {
    return OutlinedButton(
      onPressed: _isEnabled ? widget.onPressed : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.primaryTeal,
        disabledForegroundColor: AppTheme.textMuted,
        side: BorderSide(
          color: _isEnabled ? AppTheme.primaryTeal : AppTheme.borderLight,
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _buildChild(context, AppTheme.primaryTeal),
    );
  }

  Widget _buildChild(BuildContext context, Color color) {
    if (widget.isSuccess) {
      return const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_rounded, size: 20, color: Colors.white),
          SizedBox(width: 8),
          Text(
            'Success',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      );
    }

    if (widget.isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      );
    }

    if (widget.icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(widget.icon, size: 19, color: widget.iconColor ?? color),
          const SizedBox(width: 8),
          Text(
            widget.text,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: _isEnabled ? color : AppTheme.textMuted,
            ),
          ),
        ],
      );
    }

    return Text(
      widget.text,
      style: TextStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.bold,
        color: _isEnabled ? color : AppTheme.textMuted,
      ),
    );
  }
}
