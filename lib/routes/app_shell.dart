import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/home/presentation/dashboard_screen.dart';
import '../features/products/presentation/product_list_screen.dart';

import '../features/sales/presentation/management_screen.dart';
import '../providers/dark_mode_provider.dart';
import '../providers/navigation_provider.dart';
import '../shared/widgets/custom_toast.dart';



/// Shell principal con BottomNavigationBar de 5 tabs + Drawer
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  /// Global key for the root scaffold — used by child screens to open the drawer
  static final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentIndex = ref.watch(appShellIndexProvider);

    if (!auth.isAuthenticated) {
      return const LoginScreen();
    }

    // 3 tabs del bottom nav
    final screens = <Widget>[
      const DashboardScreen(),
      const ProductListScreen(), // Producción → Productos
      const ManagementScreen(),
    ];

    final maxIndex = screens.length - 1;
    if (currentIndex > maxIndex) {
      Future.microtask(() => ref.read(appShellIndexProvider.notifier).state = 0);
    }

    return Scaffold(
      key: AppShell.scaffoldKey,
      drawer: _ChazinDrawer(
        scaffoldKey: AppShell.scaffoldKey,
        currentIndex: currentIndex,
        onNavigate: (index) {
          ref.read(appShellIndexProvider.notifier).state = index;
          Navigator.of(context).pop(); // close drawer
        },
      ),
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 38 : 13),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) => ref.read(appShellIndexProvider.notifier).state = index,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: isDark ? Colors.white38 : AppColors.grey400,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Inicio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.restaurant_menu_outlined),
              activeIcon: Icon(Icons.restaurant_menu_rounded),
              label: 'Producción',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.trending_up_rounded),
              activeIcon: Icon(Icons.trending_up_rounded),
              label: 'Ventas',
            ),
          ],
        ),
      ),
    );
  }

}

// ════════════════════════════════════════════════════════
// DRAWER — Diseño exacto del Figma Make
// ════════════════════════════════════════════════════════

class _ChazinDrawer extends ConsumerStatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final int currentIndex;
  final void Function(int) onNavigate;

  const _ChazinDrawer({
    required this.scaffoldKey,
    required this.currentIndex,
    required this.onNavigate,
  });

  @override
  ConsumerState<_ChazinDrawer> createState() => _ChazinDrawerState();
}

class _ChazinDrawerState extends ConsumerState<_ChazinDrawer> {
  bool _produccionExpanded = false;
  bool _ventasExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = ref.watch(authProvider);
    final userName = auth.user?.name ?? 'Administrador Sistema';
    final userRole = auth.user?.role.name ?? 'Administrador';

    return Drawer(
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // ─── Header & User Info Container ───
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF2C394B),
              ),
              child: Column(
                children: [
                  // Logo + Close Row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 12, 8),
                    child: Row(
                      children: [
                        ClipOval(
                          child: Image.asset(
                            'assets/chazin_logo.png',
                            width: 32,
                            height: 32,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Chazin Food',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withAlpha(26),
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.close, color: Colors.white, size: 16),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // User Avatar + Info Row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFFE25858),
                          child: Text(
                            userName.isNotEmpty ? userName[0].toUpperCase() : 'A',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                userRole,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ─── Menu Items ───
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // ADMINISTRACIÓN header
                  _sectionHeader('ADMINISTRACIÓN'),

                  // Dashboard
                  _menuItem(
                    icon: Icons.dashboard_rounded,
                    label: 'Dashboard',
                    isActive: widget.currentIndex == 0,
                    onTap: () => widget.onNavigate(0),
                  ),

                  // Producción (expandible)
                  _menuItem(
                    icon: Icons.restaurant_menu_outlined,
                    label: 'Producción',
                    hasChevron: true,
                    isExpanded: _produccionExpanded,
                    onTap: () {
                      setState(() => _produccionExpanded = !_produccionExpanded);
                    },
                  ),
                  if (_produccionExpanded) ...[
                    _subMenuItem('Productos', onTap: () => widget.onNavigate(1)),
                  ],

                  // Ventas (expandible)
                  _menuItem(
                    icon: Icons.trending_up_rounded,
                    label: 'Ventas',
                    hasChevron: true,
                    isExpanded: _ventasExpanded,
                    onTap: () {
                      setState(() => _ventasExpanded = !_ventasExpanded);
                    },
                  ),
                  if (_ventasExpanded) ...[
                    _subMenuItem('Gestión de Ventas', onTap: () => widget.onNavigate(2)),
                  ],

                  const SizedBox(height: 8),

                  // CUENTA header
                  _sectionHeader('CUENTA'),

                  // Modo Oscuro
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.dark_mode_outlined,
                          size: 22,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white60
                              : AppColors.textSecondaryLight,
                        ),
                        const SizedBox(width: 14),
                        Text(
                          'Modo Oscuro',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white70
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                        const Spacer(),
                        Consumer(
                          builder: (context, ref, _) {
                            final isDarkMode = ref.watch(darkModeProvider);
                            return Switch(
                              value: isDarkMode,
                              activeTrackColor: AppColors.primary,
                              onChanged: (v) => ref.read(darkModeProvider.notifier).state = v,
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Cerrar Sesión
                  _menuItem(
                    icon: Icons.logout_rounded,
                    label: 'Cerrar Sesión',
                    textColor: AppColors.primary,
                    onTap: () {
                      // Capture the scaffold's stable context BEFORE closing the drawer
                      final scaffoldCtx = widget.scaffoldKey.currentContext!;
                      Navigator.of(context).pop(); // Close drawer immediately!
                      _showLogoutDialog(scaffoldCtx);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: isDark ? Colors.white38 : AppColors.grey400,
        ),
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String label,
    bool isActive = false,
    bool hasChevron = false,
    bool isExpanded = false,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final itemColor = textColor ??
        (isActive
            ? Colors.white
            : isDark
                ? Colors.white70
                : AppColors.textPrimaryLight);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: isActive ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isActive ? Colors.white : (textColor ?? (isDark ? Colors.white60 : AppColors.grey500)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: itemColor,
                    ),
                  ),
                ),
                if (hasChevron)
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_down : Icons.chevron_right,
                    size: 20,
                    color: isActive ? Colors.white70 : (isDark ? Colors.white38 : AppColors.grey400),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _subMenuItem(String label, {required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 52, right: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: isDark ? Colors.white60 : AppColors.textSecondaryLight,
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext parentContext) {
    final isDark = Theme.of(parentContext).brightness == Brightness.dark;
    
    showDialog(
      context: parentContext,
      builder: (dialogCtx) {
        final dialogBg = isDark ? const Color(0xFF1E1E2E) : Colors.white;
        final titleColor = isDark ? Colors.white : const Color(0xFF1E293B);
        final subtitleColor = isDark ? Colors.white70 : const Color(0xFF334155);
        final btnCancelBg = isDark ? Colors.transparent : Colors.white;
        final btnCancelText = isDark ? Colors.white70 : const Color(0xFF334155);
        final btnCancelBorder = isDark ? Colors.white24 : const Color(0xFFCBD5E1);

        return Consumer(
          builder: (context, ref, child) {
            return Dialog(
              backgroundColor: dialogBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  // Top-right close icon "X"
                  Positioned(
                    top: 14,
                    right: 14,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(dialogCtx),
                      child: Icon(
                        Icons.close_rounded,
                        color: isDark ? Colors.white54 : const Color(0xFF64748B),
                        size: 20,
                      ),
                    ),
                  ),
                  // Main content
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Warning triangle in light yellow circle container
                        Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFEF9C3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFFD97706),
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 18),
                        // Title
                        Text(
                          '¿Cerrar sesión?',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Subtitle
                        Text(
                          '¿Estás seguro de que deseas salir del sistema?',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: subtitleColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        // Action Buttons row
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(dialogCtx),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: btnCancelBg,
                                  side: BorderSide(color: btnCancelBorder),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  'Cancelar',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: btnCancelText,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  // Show premium success toast overlay using parent context first
                                  try {
                                    CustomToast.show(
                                      parentContext,
                                      title: 'Sesión cerrada',
                                      message: 'Has salido del sistema correctamente',
                                    );
                                  } catch (e) {
                                    debugPrint("CustomToast show logout error: $e");
                                  }
                                  
                                  // Close dialog
                                  try {
                                    Navigator.pop(dialogCtx);
                                  } catch (e) {
                                    debugPrint("Navigator pop logout error: $e");
                                  }

                                  // Logout to trigger screen navigation switch
                                  ref.read(authProvider.notifier).logout();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD97706),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  'Sí, salir',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
