import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/custom_toast.dart';
import '../providers/users_provider.dart';

class UserListScreen extends ConsumerStatefulWidget {
  const UserListScreen({super.key});

  @override
  ConsumerState<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends ConsumerState<UserListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allUsers = ref.watch(usersProvider);
    final filteredUsers = ref.watch(filteredUsersProvider);
    final roleFilter = ref.watch(userRoleFilterProvider);
    final statusFilter = ref.watch(userStatusFilterProvider);

    // Metrics calculations
    final totalCount = allUsers.length;
    final activeCount = allUsers.where((u) => u.isActive).length;
    final adminCount = allUsers.where((u) => u.isAdmin).length;
    final employeeCount = allUsers.where((u) => u.role == UserRole.employee).length;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Gestión de Usuarios',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            tooltip: 'Nuevo Usuario',
            onPressed: () => _showEditUserModal(context, null),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.read(userSearchQueryProvider.notifier).state = '';
            ref.read(userRoleFilterProvider.notifier).state = 'Todos';
            ref.read(userStatusFilterProvider.notifier).state = 'Todos';
            _searchController.clear();
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Administra los usuarios del sistema, sus roles y permisos',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ─── 4 METRIC CARDS ───
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final double itemWidth = (constraints.maxWidth - 12) / 2;
                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _buildMetricCard(
                                width: itemWidth,
                                title: 'Total Usuarios',
                                value: '$totalCount',
                                icon: Icons.people_alt_rounded,
                                iconBgColor: const Color(0xFFEFF6FF),
                                iconColor: const Color(0xFF2563EB),
                                isDark: isDark,
                              ),
                              _buildMetricCard(
                                width: itemWidth,
                                title: 'Usuarios Activos',
                                value: '$activeCount',
                                icon: Icons.check_circle_rounded,
                                iconBgColor: const Color(0xFFECFDF5),
                                iconColor: const Color(0xFF10B981),
                                isDark: isDark,
                              ),
                              _buildMetricCard(
                                width: itemWidth,
                                title: 'Administradores',
                                value: '$adminCount',
                                icon: Icons.admin_panel_settings_rounded,
                                iconBgColor: const Color(0xFFF3E8FF),
                                iconColor: const Color(0xFF9333EA),
                                isDark: isDark,
                              ),
                              _buildMetricCard(
                                width: itemWidth,
                                title: 'Empleados',
                                value: '$employeeCount',
                                icon: Icons.badge_rounded,
                                iconBgColor: const Color(0xFFFFEDD5),
                                iconColor: const Color(0xFFEA580C),
                                isDark: isDark,
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // ─── SEARCH BAR & FILTERS ───
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? Colors.white.withAlpha(15) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Column(
                          children: [
                            // Search field
                            TextField(
                              controller: _searchController,
                              onChanged: (val) {
                                ref.read(userSearchQueryProvider.notifier).state = val;
                              },
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                              ),
                              decoration: InputDecoration(
                                hintText: 'Buscar por nombre, correo o cédula...',
                                hintStyle: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                                ),
                                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF94A3B8)),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.close_rounded, size: 18),
                                        onPressed: () {
                                          _searchController.clear();
                                          ref.read(userSearchQueryProvider.notifier).state = '';
                                        },
                                      )
                                    : null,
                                filled: true,
                                fillColor: isDark ? Colors.white.withAlpha(8) : const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Filters Row
                            Row(
                              children: [
                                // Rol Dropdown
                                Expanded(
                                  child: _buildFilterDropdown(
                                    label: 'Rol',
                                    value: roleFilter,
                                    items: const ['Todos', 'Administrador', 'Empleado', 'Cajero', 'Cocinero'],
                                    onChanged: (val) {
                                      if (val != null) {
                                        ref.read(userRoleFilterProvider.notifier).state = val;
                                      }
                                    },
                                    isDark: isDark,
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Estado Dropdown
                                Expanded(
                                  child: _buildFilterDropdown(
                                    label: 'Estado',
                                    value: statusFilter,
                                    items: const ['Todos', 'Activo', 'Inactivo'],
                                    onChanged: (val) {
                                      if (val != null) {
                                        ref.read(userStatusFilterProvider.notifier).state = val;
                                      }
                                    },
                                    isDark: isDark,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Section Title & Add Button Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Lista de Usuarios (${filteredUsers.length})',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _showEditUserModal(context, null),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: Text(
                              'Nuevo Usuario',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              // ─── USER LIST / CARDS ───
              filteredUsers.isEmpty
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            const Icon(Icons.person_search_rounded, size: 48, color: Color(0xFF94A3B8)),
                            const SizedBox(height: 12),
                            Text(
                              'No se encontraron usuarios',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : const Color(0xFF475569),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Intenta ajustar los criterios de búsqueda o filtros',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final user = filteredUsers[index];
                            return _buildUserCard(context, user, isDark);
                          },
                          childCount: filteredUsers.length,
                        ),
                      ),
                    ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }

  // Metric Card helper
  Widget _buildMetricCard({
    required double width,
    required String title,
    required String value,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required bool isDark,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withAlpha(15) : const Color(0xFFE2E8F0),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? iconColor.withAlpha(30) : iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Filter Dropdown Helper
  Widget _buildFilterDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(8) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.white.withAlpha(15) : const Color(0xFFE2E8F0),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF94A3B8)),
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
          dropdownColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          onChanged: onChanged,
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text('$label: $item'),
            );
          }).toList(),
        ),
      ),
    );
  }

  // User Card Item
  Widget _buildUserCard(BuildContext context, User user, bool isDark) {
    Color roleBg;
    Color roleTxt;

    switch (user.role) {
      case UserRole.admin:
        roleBg = isDark ? const Color(0xFF581C87) : const Color(0xFFF3E8FF);
        roleTxt = isDark ? const Color(0xFFE9D5FF) : const Color(0xFF7E22CE);
        break;
      case UserRole.cashier:
        roleBg = isDark ? const Color(0xFF1E3A8A) : const Color(0xFFEFF6FF);
        roleTxt = isDark ? const Color(0xFFBFDBFE) : const Color(0xFF1D4ED8);
        break;
      case UserRole.chef:
        roleBg = isDark ? const Color(0xFF701A75) : const Color(0xFFFCE7F3);
        roleTxt = isDark ? const Color(0xFFFBCFE8) : const Color(0xFFBE185D);
        break;
      case UserRole.employee:
        roleBg = isDark ? const Color(0xFF7C2D12) : const Color(0xFFFFEDD5);
        roleTxt = isDark ? const Color(0xFFFED7AA) : const Color(0xFFC2410C);
        break;
    }

    final statusBg = user.isActive
        ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5))
        : (isDark ? const Color(0xFF451A03) : const Color(0xFFFEF2F2));
    final statusTxt = user.isActive
        ? (isDark ? const Color(0xFFA7F3D0) : const Color(0xFF047857))
        : (isDark ? const Color(0xFFFECACA) : const Color(0xFFB91C1C));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withAlpha(15) : const Color(0xFFE2E8F0),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(5),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary,
                child: Text(
                  user.initials,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Name & Email
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Detail Icon Eye
              IconButton(
                icon: const Icon(Icons.visibility_outlined, size: 20, color: Color(0xFF64748B)),
                tooltip: 'Ver Detalle',
                onPressed: () => _showUserDetailsModal(context, user),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),

          // Metadata row (Document, Role badge, Status badge)
          Row(
            children: [
              // Document
              Text(
                '${user.tipoDocumento} ${user.documento}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                ),
              ),
              const Spacer(),

              // Role Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: roleBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  user.roleName,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: roleTxt,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: statusTxt,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      user.isActive ? 'Activo' : 'Inactivo',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusTxt,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Action Buttons Bar (Edit, Change Password, Toggle Status)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Change Password Button
              TextButton.icon(
                onPressed: () => _showChangePasswordModal(context, user),
                icon: const Icon(Icons.key_rounded, size: 16, color: Color(0xFFD97706)),
                label: Text(
                  'Contraseña',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFD97706),
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 8),

              // Edit Button
              TextButton.icon(
                onPressed: () => _showEditUserModal(context, user),
                icon: const Icon(Icons.edit_rounded, size: 16, color: Color(0xFF2563EB)),
                label: Text(
                  'Editar',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2563EB),
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 8),

              // Toggle Status Button
              IconButton(
                icon: Icon(
                  user.isActive ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
                  size: 28,
                  color: user.isActive ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                ),
                tooltip: user.isActive ? 'Desactivar usuario' : 'Activar usuario',
                onPressed: () {
                  ref.read(usersProvider.notifier).toggleStatus(user.id);
                  CustomToast.show(
                    context,
                    title: user.isActive ? 'Usuario desactivado' : 'Usuario activado',
                    message: 'El estado de ${user.name} ha sido actualizado',
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  // 1. DETALLE DEL USUARIO MODAL (Fiel a Screenshot 2)
  // ════════════════════════════════════════════════════════
  void _showUserDetailsModal(BuildContext context, User user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            top: 16,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Indicator Handle & Title Row
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Detalle del Usuario',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Header Card Profile Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withAlpha(8) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white.withAlpha(15) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        user.initials,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.email,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: user.isActive ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        user.isActive ? 'Activo' : 'Inactivo',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: user.isActive ? const Color(0xFF047857) : const Color(0xFFB91C1C),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Grid Fields List
              _buildDetailTile('Cédula / Documento', '${user.tipoDocumento} ${user.documento}', Icons.badge_outlined, isDark),
              _buildDetailTile('Nombre Completo', user.name, Icons.person_outline_rounded, isDark),
              _buildDetailTile('Correo Electrónico', user.email, Icons.email_outlined, isDark),
              _buildDetailTile('Teléfono', user.telefono, Icons.phone_outlined, isDark),
              _buildDetailTile('Rol', user.roleName, Icons.admin_panel_settings_outlined, isDark),
              _buildDetailTile('Fecha de Registro', user.fechaRegistro, Icons.calendar_today_outlined, isDark),
              _buildDetailTile('Último Acceso', user.ultimoAcceso, Icons.access_time_rounded, isDark),

              const SizedBox(height: 20),

              // Bottom Buttons Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Cerrar',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showEditUserModal(context, user);
                      },
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      label: Text(
                        'Editar Usuario',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailTile(String label, String value, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF64748B)),
          const SizedBox(width: 10),
          Text(
            '$label:',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  // 2. EDITAR / CREAR USUARIO MODAL (Fiel a Screenshot 3)
  // ════════════════════════════════════════════════════════
  void _showEditUserModal(BuildContext context, User? user) {
    final isEditing = user != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final docTypeCtrl = ValueNotifier<String>(user?.tipoDocumento ?? 'C.C.');
    final docCtrl = TextEditingController(text: user?.documento ?? '');
    final nameCtrl = TextEditingController(text: user?.name ?? '');
    final emailCtrl = TextEditingController(text: user?.email ?? '');
    final phoneCtrl = TextEditingController(text: user?.telefono ?? '');
    final roleCtrl = ValueNotifier<String>(user?.roleName ?? 'Empleado');
    final statusCtrl = ValueNotifier<String>(user?.isActive ?? true ? 'Activo' : 'Inactivo');
    final notifyEmailCtrl = ValueNotifier<bool>(true);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                top: 16,
                left: 20,
                right: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle & Title Row
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEditing ? 'Editar Usuario' : 'Nuevo Usuario',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Tipo Documento Dropdown
                    _buildFormFieldLabel('Tipo de Documento', isDark),
                    ValueListenableBuilder<String>(
                      valueListenable: docTypeCtrl,
                      builder: (context, val, _) {
                        return DropdownButtonFormField<String>(
                          initialValue: val,
                          decoration: _inputDecoration(isDark),
                          items: const [
                            DropdownMenuItem(value: 'C.C.', child: Text('Cédula de Ciudadanía (C.C.)')),
                            DropdownMenuItem(value: 'C.E.', child: Text('Cédula de Extranjería (C.E.)')),
                            DropdownMenuItem(value: 'Pasaporte', child: Text('Pasaporte')),
                          ],
                          onChanged: (v) => docTypeCtrl.value = v!,
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    // Documento Number
                    _buildFormFieldLabel('Número de Documento', isDark),
                    TextField(
                      controller: docCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(isDark, hint: 'Ej. 1.098.765.432'),
                    ),
                    const SizedBox(height: 12),

                    // Nombre Completo
                    _buildFormFieldLabel('Nombre Completo', isDark),
                    TextField(
                      controller: nameCtrl,
                      decoration: _inputDecoration(isDark, hint: 'Ej. Carlos Andrés Mendoza'),
                    ),
                    const SizedBox(height: 12),

                    // Correo Electrónico
                    _buildFormFieldLabel('Correo Electrónico', isDark),
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration(isDark, hint: 'ejemplo@chazinfood.com'),
                    ),
                    const SizedBox(height: 12),

                    // Teléfono
                    _buildFormFieldLabel('Teléfono', isDark),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: _inputDecoration(isDark, hint: '+57 300 000 0000'),
                    ),
                    const SizedBox(height: 12),

                    // Rol Dropdown
                    _buildFormFieldLabel('Rol', isDark),
                    ValueListenableBuilder<String>(
                      valueListenable: roleCtrl,
                      builder: (context, val, _) {
                        return DropdownButtonFormField<String>(
                          initialValue: val,
                          decoration: _inputDecoration(isDark),
                          items: const [
                            DropdownMenuItem(value: 'Administrador', child: Text('Administrador')),
                            DropdownMenuItem(value: 'Empleado', child: Text('Empleado')),
                            DropdownMenuItem(value: 'Cajero', child: Text('Cajero')),
                            DropdownMenuItem(value: 'Cocinero', child: Text('Cocinero')),
                          ],
                          onChanged: (v) => roleCtrl.value = v!,
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    // Estado Dropdown
                    _buildFormFieldLabel('Estado', isDark),
                    ValueListenableBuilder<String>(
                      valueListenable: statusCtrl,
                      builder: (context, val, _) {
                        return DropdownButtonFormField<String>(
                          initialValue: val,
                          decoration: _inputDecoration(isDark),
                          items: const [
                            DropdownMenuItem(value: 'Activo', child: Text('Activo')),
                            DropdownMenuItem(value: 'Inactivo', child: Text('Inactivo')),
                          ],
                          onChanged: (v) => statusCtrl.value = v!,
                        );
                      },
                    ),
                    const SizedBox(height: 14),

                    // Checkbox "Enviar notificación por correo al guardar cambios"
                    ValueListenableBuilder<bool>(
                      valueListenable: notifyEmailCtrl,
                      builder: (context, isChecked, _) {
                        return CheckboxListTile(
                          value: isChecked,
                          onChanged: (v) => notifyEmailCtrl.value = v ?? false,
                          title: Text(
                            'Enviar notificación por correo al guardar cambios',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isDark ? Colors.white70 : const Color(0xFF475569),
                            ),
                          ),
                          activeColor: AppColors.primary,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // Bottom Buttons Row
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Cancelar',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              if (nameCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty) {
                                CustomToast.show(
                                  context,
                                  title: 'Campos requeridos',
                                  message: 'Por favor ingresa nombre y correo electrónico',
                                  isError: true,
                                );
                                return;
                              }

                              UserRole selectedRole = UserRole.employee;
                              if (roleCtrl.value == 'Administrador') selectedRole = UserRole.admin;
                              if (roleCtrl.value == 'Cajero') selectedRole = UserRole.cashier;
                              if (roleCtrl.value == 'Cocinero') selectedRole = UserRole.chef;

                              final newUser = User(
                                id: user?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                                name: nameCtrl.text.trim(),
                                email: emailCtrl.text.trim(),
                                role: selectedRole,
                                tipoDocumento: docTypeCtrl.value,
                                documento: docCtrl.text.trim(),
                                telefono: phoneCtrl.text.trim(),
                                isActive: statusCtrl.value == 'Activo',
                                fechaRegistro: user?.fechaRegistro ?? 'Hoy',
                                ultimoAcceso: user?.ultimoAcceso ?? 'Recién registrado',
                              );

                              if (isEditing) {
                                ref.read(usersProvider.notifier).updateUser(newUser);
                              } else {
                                ref.read(usersProvider.notifier).addUser(newUser);
                              }

                              Navigator.pop(ctx);
                              CustomToast.show(
                                context,
                                title: isEditing ? 'Usuario actualizado' : 'Usuario creado',
                                message: 'Los datos de ${newUser.name} fueron guardados con éxito',
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Guardar Cambios',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════
  // 3. CAMBIAR CONTRASEÑA MODAL (Fiel a Screenshot 4)
  // ════════════════════════════════════════════════════════
  void _showChangePasswordModal(BuildContext context, User user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final passCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    final hidePass = ValueNotifier<bool>(true);
    final hideConfirmPass = ValueNotifier<bool>(true);
    final forceChangeNextLogin = ValueNotifier<bool>(true);
    final sendEmail = ValueNotifier<bool>(true);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                top: 16,
                left: 20,
                right: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle & Title Row
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Cambiar Contraseña',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    Text(
                      'Usuario: ${user.name}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Field 1: Nueva Contraseña
                    _buildFormFieldLabel('Nueva Contraseña', isDark),
                    ValueListenableBuilder<bool>(
                      valueListenable: hidePass,
                      builder: (context, isHidden, _) {
                        return TextField(
                          controller: passCtrl,
                          obscureText: isHidden,
                          decoration: _inputDecoration(
                            isDark,
                            hint: 'Ingresa la nueva contraseña',
                            suffixIcon: IconButton(
                              icon: Icon(
                                isHidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                size: 20,
                                color: const Color(0xFF94A3B8),
                              ),
                              onPressed: () => hidePass.value = !isHidden,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    // Field 2: Confirmar Nueva Contraseña
                    _buildFormFieldLabel('Confirmar Nueva Contraseña', isDark),
                    ValueListenableBuilder<bool>(
                      valueListenable: hideConfirmPass,
                      builder: (context, isHidden, _) {
                        return TextField(
                          controller: confirmPassCtrl,
                          obscureText: isHidden,
                          decoration: _inputDecoration(
                            isDark,
                            hint: 'Repite la nueva contraseña',
                            suffixIcon: IconButton(
                              icon: Icon(
                                isHidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                size: 20,
                                color: const Color(0xFF94A3B8),
                              ),
                              onPressed: () => hideConfirmPass.value = !isHidden,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),

                    // Checkbox 1: Obligar al usuario a cambiar la contraseña en el próximo inicio de sesión
                    ValueListenableBuilder<bool>(
                      valueListenable: forceChangeNextLogin,
                      builder: (context, isChecked, _) {
                        return CheckboxListTile(
                          value: isChecked,
                          onChanged: (v) => forceChangeNextLogin.value = v ?? false,
                          title: Text(
                            'Obligar al usuario a cambiar la contraseña en el próximo inicio de sesión',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isDark ? Colors.white70 : const Color(0xFF475569),
                            ),
                          ),
                          activeColor: AppColors.primary,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                        );
                      },
                    ),

                    // Checkbox 2: Enviar nueva contraseña por correo electrónico
                    ValueListenableBuilder<bool>(
                      valueListenable: sendEmail,
                      builder: (context, isChecked, _) {
                        return CheckboxListTile(
                          value: isChecked,
                          onChanged: (v) => sendEmail.value = v ?? false,
                          title: Text(
                            'Enviar nueva contraseña por correo electrónico',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isDark ? Colors.white70 : const Color(0xFF475569),
                            ),
                          ),
                          activeColor: AppColors.primary,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // Bottom Buttons Row
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Cancelar',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              if (passCtrl.text.isEmpty || confirmPassCtrl.text.isEmpty) {
                                CustomToast.show(
                                  context,
                                  title: 'Campos vacíos',
                                  message: 'Ingresa y confirma la nueva contraseña',
                                  isError: true,
                                );
                                return;
                              }

                              if (passCtrl.text != confirmPassCtrl.text) {
                                CustomToast.show(
                                  context,
                                  title: 'Contraseñas no coinciden',
                                  message: 'Asegúrate de que ambas contraseñas sean idénticas',
                                  isError: true,
                                );
                                return;
                              }

                              Navigator.pop(ctx);
                              CustomToast.show(
                                context,
                                title: 'Contraseña actualizada',
                                message: 'La contraseña de ${user.name} fue cambiada con éxito',
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD97706),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Actualizar Contraseña',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Form Label Helper
  Widget _buildFormFieldLabel(String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white70 : const Color(0xFF334155),
        ),
      ),
    );
  }

  // Input Decoration Helper
  InputDecoration _inputDecoration(bool isDark, {String? hint, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.white38 : const Color(0xFF94A3B8)),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: isDark ? Colors.white.withAlpha(8) : const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}
