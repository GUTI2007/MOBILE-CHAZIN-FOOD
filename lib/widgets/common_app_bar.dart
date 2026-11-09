import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../features/auth/providers/auth_provider.dart';
import '../providers/dark_mode_provider.dart';
import '../routes/app_shell.dart';

/// Unified AppBar widget used across all screens for consistent navigation.
///
/// Supports:
/// - [title] — plain text title
/// - [showBrandHeader] — shows the Chazin Food logo + name (for main tabs)
/// - [showDarkModeToggle] — shows light/dark mode toggle
/// - [showRefresh] / [onRefresh] — shows a refresh button
/// - [onClose] — shows a close (X) button (for sub-screens / modals)
/// - [showDrawerMenu] — shows a circular profile avatar to open the drawer
class CommonAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String? title;
  final bool showBrandHeader;
  final bool showDarkModeToggle;
  final bool showRefresh;
  final bool showDrawerMenu;
  final VoidCallback? onClose;
  final VoidCallback? onRefresh;

  const CommonAppBar({
    super.key,
    this.title,
    this.showBrandHeader = false,
    this.showDarkModeToggle = false,
    this.showRefresh = false,
    this.showDrawerMenu = false,
    this.onClose,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = ref.watch(authProvider);
    final userName = auth.user?.name ?? 'A';
    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : 'A';

    Widget? titleWidget;
    if (showBrandHeader) {
      titleWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(
              'assets/chazin_logo.png',
              width: 28,
              height: 28,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Chazin Food',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 18),
          ),
        ],
      );
    } else if (title != null) {
      titleWidget = Text(title!);
    }

    return AppBar(
      leading: showDrawerMenu
          ? Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () => AppShell.scaffoldKey.currentState?.openDrawer(),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFFF3E55),
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            )
          : null,
      title: titleWidget,
      centerTitle: showBrandHeader,
      actions: [
        if (showRefresh && onRefresh != null)
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: onRefresh,
          ),
        if (showDarkModeToggle)
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            onPressed: () {
              ref.read(darkModeProvider.notifier).state = !isDark;
            },
          ),
        if (onClose != null)
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: onClose,
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
