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
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final notif = context.watch<NotificationService>();
    final currentRole = auth.currentRole;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.border, width: 1)),
      ),
      child: Row(
        children: [
          // Brand Logo
          Row(
            children: [
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
              const SizedBox(width: 8),
              if (!isMobile)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DeskAI',
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
                )
              else
                const Text(
                  'DeskAI',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
            ],
          ),
          const Spacer(),

          // 1-Click Role Switcher
          Container(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 6 : 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.swap_horiz, size: 16, color: AppTheme.primary),
                SizedBox(width: isMobile ? 2 : 6),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: currentRole,
                    isDense: true,
                    icon: const Icon(Icons.arrow_drop_down, color: AppTheme.primary, size: 18),
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: isMobile ? 11 : 12,
                      fontWeight: FontWeight.w700,
                    ),
                    items: isMobile
                        ? const [
                            DropdownMenuItem(value: 'REQUESTER', child: Text('Requester')),
                            DropdownMenuItem(value: 'OPERATOR', child: Text('Operator')),
                            DropdownMenuItem(value: 'TEAM_LEAD', child: Text('Team Lead')),
                            DropdownMenuItem(value: 'MANAGER', child: Text('Manager')),
                            DropdownMenuItem(value: 'ADMIN', child: Text('Admin')),
                            DropdownMenuItem(
                              value: 'LOGOUT',
                              child: Text('🚪 Sign Out (Logout)', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold)),
                            ),
                          ]
                        : const [
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
          SizedBox(width: isMobile ? 4 : 10),

          // Notification Bell
          IconButton(
            tooltip: 'In-app Notifications',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_outlined, color: AppTheme.textSecondary, size: 19),
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
          SizedBox(width: isMobile ? 4 : 8),

          // Prominent User Profile & Logout
          if (auth.currentUser != null) ...[
            if (!isMobile) ...[
              CircleAvatar(
                radius: 13,
                backgroundColor: AppTheme.primary,
                child: Text(
                  auth.currentUser!.fullName.isNotEmpty
                      ? auth.currentUser!.fullName[0]
                      : 'U',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
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
              const SizedBox(width: 8),
            ],
            // Clearly Visible Red Logout Button for Mobile & Desktop
            InkWell(
              onTap: () => auth.logout(),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 7 : 10,
                  vertical: isMobile ? 5 : 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.logout_rounded, size: 14, color: AppTheme.error),
                    const SizedBox(width: 3),
                    Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: isMobile ? 10 : 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
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
