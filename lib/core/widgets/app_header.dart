import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';

/// Reusable Back Button component used across the application.
class AppBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String? fallbackRoute;
  final Color? color;
  final bool isDark;

  const AppBackButton({
    super.key,
    this.onPressed,
    this.fallbackRoute,
    this.color,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveFgColor = color ?? (isDark ? Colors.white : AppTheme.textDarkPrimary);
    final buttonBg = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : AppTheme.primaryLightTeal.withValues(alpha: 0.7);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.2)
        : AppTheme.borderLight.withValues(alpha: 0.8);

    return Padding(
      padding: const EdgeInsets.only(left: 12.0, top: 8.0, bottom: 8.0, right: 4.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (onPressed != null) {
              onPressed!();
            } else if (context.canPop()) {
              context.pop();
            } else if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go(fallbackRoute ?? '/dashboard');
            }
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: buttonBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: borderColor,
                width: 1,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.arrow_back_rounded,
                color: effectiveFgColor,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Unified App Header component for consistent top navigation across all screens.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final String? subtitle;
  final Widget? titleWidget;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final String? fallbackRoute;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool centerTitle;
  final double elevation;
  final PreferredSizeWidget? bottom;
  final bool isDark;

  const AppHeader({
    super.key,
    this.title,
    this.subtitle,
    this.titleWidget,
    this.showBackButton = true,
    this.onBackPressed,
    this.fallbackRoute,
    this.actions,
    this.backgroundColor,
    this.foregroundColor,
    this.centerTitle = false,
    this.elevation = 0,
    this.bottom,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBg = backgroundColor ?? (isDark ? AppTheme.primaryDeepTeal : AppTheme.surfaceWhite);
    final effectiveFg = foregroundColor ?? (isDark ? Colors.white : AppTheme.textDarkPrimary);

    Widget? leadingWidget;
    if (showBackButton) {
      leadingWidget = AppBackButton(
        onPressed: onBackPressed,
        fallbackRoute: fallbackRoute,
        color: effectiveFg,
        isDark: isDark,
      );
    }

    Widget? titleContent;
    if (titleWidget != null) {
      titleContent = titleWidget;
    } else if (title != null) {
      if (subtitle != null && subtitle!.isNotEmpty) {
        titleContent = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: centerTitle ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          children: [
            Text(
              title!,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: effectiveFg,
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: effectiveFg.withValues(alpha: 0.7),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      } else {
        titleContent = Text(
          title!,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: effectiveFg,
            letterSpacing: -0.3,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      }
    }

    return AppBar(
      elevation: elevation,
      scrolledUnderElevation: 0,
      backgroundColor: effectiveBg,
      surfaceTintColor: Colors.transparent,
      centerTitle: centerTitle,
      automaticallyImplyLeading: false,
      leadingWidth: showBackButton ? 56 : null,
      leading: leadingWidget,
      title: titleContent,
      actions: actions,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0.0),
      );
}
