import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';


/// Modelo simple de cliente
class Client {
  final String id;
  final String name;
  final String email;
  final String phone;
  final int totalOrders;
  final double totalSpent;
  final DateTime lastOrder;
  final bool isActive;

  const Client({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.totalOrders,
    required this.totalSpent,
    required this.lastOrder,
    this.isActive = true,
  });
}

/// Mock data de clientes
final _mockClients = [
  Client(
    id: 'cli_001', name: 'Carlos Rodríguez', email: 'carlos@email.com',
    phone: '+57 300 123 4567', totalOrders: 24, totalSpent: 456000,
    lastOrder: DateTime(2026, 6, 28),
  ),
  Client(
    id: 'cli_002', name: 'María González', email: 'maria@email.com',
    phone: '+57 310 234 5678', totalOrders: 18, totalSpent: 312000,
    lastOrder: DateTime(2026, 6, 30),
  ),
  Client(
    id: 'cli_003', name: 'Andrés López', email: 'andres@email.com',
    phone: '+57 320 345 6789', totalOrders: 31, totalSpent: 625000,
    lastOrder: DateTime(2026, 7, 1),
  ),
  Client(
    id: 'cli_004', name: 'Laura Martínez', email: 'laura@email.com',
    phone: '+57 315 456 7890', totalOrders: 12, totalSpent: 198000,
    lastOrder: DateTime(2026, 6, 25),
  ),
  Client(
    id: 'cli_005', name: 'Juan Pérez', email: 'juan@email.com',
    phone: '+57 301 567 8901', totalOrders: 8, totalSpent: 145000,
    lastOrder: DateTime(2026, 6, 20),
  ),
];

/// Pantalla de gestión de clientes — sub-ítem de Ventas en drawer
class ClientListScreen extends ConsumerWidget {
  const ClientListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
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
            Text('Chazin Food', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 18)),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header ───
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gestión de Clientes',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Administra los clientes del negocio',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDark ? Colors.white54 : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ─── Stats Row ───
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _clientStat(
                  icon: Icons.people_outline,
                  iconColor: const Color(0xFF3B82F6),
                  label: 'Total Clientes',
                  value: _mockClients.length.toString(),
                  isDark: isDark,
                ),
                const SizedBox(width: 12),
                _clientStat(
                  icon: Icons.star_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  label: 'Más Frecuente',
                  value: 'Andrés L.',
                  isDark: isDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ─── Search ───
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar cliente...',
                hintStyle: GoogleFonts.inter(
                  color: isDark ? Colors.white30 : AppColors.grey400,
                  fontSize: 14,
                ),
                prefixIcon: Icon(Icons.search_rounded, color: isDark ? Colors.white38 : AppColors.grey400),
                filled: true,
                fillColor: isDark ? AppColors.cardDark : AppColors.grey50,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDark ? Colors.white10 : AppColors.grey200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDark ? Colors.white10 : AppColors.grey200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ─── Client List ───
          Expanded(
            child: AnimationLimiter(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _mockClients.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final client = _mockClients[index];
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 400),
                    child: SlideAnimation(
                      verticalOffset: 30,
                      child: FadeInAnimation(
                        child: _ClientCard(client: client, isDark: isDark),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _clientStat({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: isDark ? Border.all(color: Colors.white.withAlpha(13)) : null,
          boxShadow: isDark
              ? null
              : [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withAlpha(26),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.inter(fontSize: 11, color: isDark ? Colors.white54 : AppColors.textSecondaryLight)),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: isDark ? Colors.white : AppColors.textPrimaryLight),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClientCard extends StatelessWidget {
  final Client client;
  final bool isDark;

  const _ClientCard({required this.client, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isDark ? Border.all(color: Colors.white.withAlpha(13)) : null,
        boxShadow: isDark
            ? null
            : [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary.withAlpha(26),
            child: Text(
              client.name[0],
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.name,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${client.totalOrders} pedidos • ${client.phone}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.success.withAlpha(26),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _formatCurrency(client.totalSpent),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.grey400, size: 20),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    final str = amount.toStringAsFixed(0);
    final buffer = StringBuffer('\$');
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }
}
