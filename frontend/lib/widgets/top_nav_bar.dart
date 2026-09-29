import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

class TopNavBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const TopNavBar({
    super.key,
    required this.title,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final notif = context.watch<NotificationService>();
    final currentRole = auth.currentRole;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Container(
      height: 60,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.border, width: 1)),
      ),
      child: isMobile
          ? _buildMobileHeader(context, auth, notif, currentRole)
          : _buildDesktopHeader(context, auth, notif, currentRole),
    );
  }

  Widget _buildMobileHeader(
    BuildContext context,
    AuthState auth,
    NotificationService notif,
    String currentRole,
  ) {
    final userName = auth.currentUser?.fullName ?? 'User';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Brand & User Role Chip (Tappable to switch persona)
        InkWell(
          onTap: () => _showMobileProfileSheet(context, auth),
          borderRadius: BorderRadius.circular(8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Center(
                  child: Icon(Icons.bolt, color: Colors.white, size: 18),
                ),
              ),
              const SizedBox(width: 6),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DeskAI',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    currentRole,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Actions: Notifications + Switch Role + PROMINENT LOGOUT BUTTON
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Persona Switcher Icon
            IconButton(
              tooltip: 'Switch Persona',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              icon: const Icon(Icons.swap_horiz, color: AppTheme.primary, size: 20),
              onPressed: () => _showMobileProfileSheet(context, auth),
            ),
            const SizedBox(width: 2),

            // Notifications Bell
            IconButton(
              tooltip: 'Notifications',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_outlined, color: AppTheme.textSecondary, size: 20),
                  if (notif.unreadCount > 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: AppTheme.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                        child: Text(
                          '${notif.unreadCount}',
                          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: () => _showNotificationsModal(context, notif),
            ),
            const SizedBox(width: 6),

            // EXPLICIT SOLID RED LOGOUT BUTTON FOR MOBILE
            ElevatedButton.icon(
              onPressed: () => auth.logout(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: const Size(64, 32),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                elevation: 0,
              ),
              icon: const Icon(Icons.logout, size: 14, color: Colors.white),
              label: const Text(
                'Logout',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopHeader(
    BuildContext context,
    AuthState auth,
    NotificationService notif,
    String currentRole,
  ) {
    return Row(
      children: [
        // Brand Logo
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Icon(Icons.bolt, color: Colors.white, size: 20),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'DeskAI Operations',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
        const Spacer(),

        // 1-Click Role Switcher Dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.primaryLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.swap_horiz, size: 16, color: AppTheme.primary),
              const SizedBox(width: 6),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: currentRole,
                  isDense: true,
                  icon: const Icon(Icons.arrow_drop_down, color: AppTheme.primary, size: 18),
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'REQUESTER', child: Text('Requester (Alex Rivera)')),
                    DropdownMenuItem(value: 'OPERATOR', child: Text('Operator (Priya N.)')),
                    DropdownMenuItem(value: 'TEAM_LEAD', child: Text('Team Lead (Sarah J.)')),
                    DropdownMenuItem(value: 'MANAGER', child: Text('Manager (Marcus V.)')),
                    DropdownMenuItem(value: 'ADMIN', child: Text('Super Admin (Elena R.)')),
                    DropdownMenuItem(
                      value: 'LOGOUT',
                      child: Text('🚪 Sign Out (Logout)', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold)),
                    ),
                  ],
                  onChanged: (newRole) {
                    if (newRole == 'LOGOUT') {
                      auth.logout();
                    } else if (newRole != null && newRole != currentRole) {
                      auth.switchDemoRole(newRole);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),

        // Notification Bell
        IconButton(
          tooltip: 'In-app Notifications',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_outlined, color: AppTheme.textSecondary, size: 20),
              if (notif.unreadCount > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: AppTheme.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                    child: Text(
                      '${notif.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          onPressed: () => _showNotificationsModal(context, notif),
        ),
        const SizedBox(width: 10),

        // User Avatar & Name
        if (auth.currentUser != null) ...[
          CircleAvatar(
            radius: 14,
            backgroundColor: AppTheme.primary,
            child: Text(
              auth.currentUser!.fullName.isNotEmpty
                  ? auth.currentUser!.fullName[0]
                  : 'U',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            auth.currentUser!.fullName,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(width: 10),
          // Prominent Desktop Logout Button
          ElevatedButton.icon(
            onPressed: () => auth.logout(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(80, 32),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              elevation: 0,
            ),
            icon: const Icon(Icons.logout, size: 14, color: Colors.white),
            label: const Text(
              'Logout',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ],
    );
  }

  void _showMobileProfileSheet(BuildContext context, AuthState auth) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.primary,
                  child: Text(
                    auth.currentUser?.fullName.isNotEmpty == true
                        ? auth.currentUser!.fullName[0]
                        : 'U',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        auth.currentUser?.fullName ?? 'Alex Rivera',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        auth.currentUser?.email ?? 'requester@company.com',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'SWITCH PERSONA ROLE',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMuted, letterSpacing: 0.5),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPersonaChip(ctx, auth, 'Requester', 'REQUESTER'),
                _buildPersonaChip(ctx, auth, 'Operator', 'OPERATOR'),
                _buildPersonaChip(ctx, auth, 'Team Lead', 'TEAM_LEAD'),
                _buildPersonaChip(ctx, auth, 'Manager', 'MANAGER'),
                _buildPersonaChip(ctx, auth, 'Admin', 'ADMIN'),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Log Out of DeskAI', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.pop(ctx);
                  auth.logout();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonaChip(BuildContext ctx, AuthState auth, String label, String role) {
    final isSelected = auth.currentRole == role;
    return ActionChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.white : AppTheme.primary,
        ),
      ),
      backgroundColor: isSelected ? AppTheme.primary : AppTheme.primaryLight,
      onPressed: () {
        Navigator.pop(ctx);
        auth.switchDemoRole(role);
      },
    );
  }

  void _showNotificationsModal(BuildContext context, NotificationService notif) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('In-App Notifications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              if (notif.unreadCount > 0)
                TextButton(
                  onPressed: () {
                    notif.markAllAsRead();
                  },
                  child: const Text('Mark all read', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
          content: SizedBox(
            width: 400,
            height: 350,
            child: notif.notifications.isEmpty
                ? const Center(
                    child: Text('No active notifications', style: TextStyle(color: AppTheme.textMuted)),
                  )
                : ListView.separated(
                    itemCount: notif.notifications.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, idx) {
                      final n = notif.notifications[idx];
                      return ListTile(
                        leading: Icon(
                          n.isRead ? Icons.mark_email_read_outlined : Icons.mark_email_unread_rounded,
                          color: n.isRead ? AppTheme.textMuted : AppTheme.primary,
                        ),
                        title: Text(n.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        subtitle: Text(n.message, style: const TextStyle(fontSize: 12)),
                        onTap: () {
                          if (!n.isRead) notif.markAsRead(n.id);
                        },
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
