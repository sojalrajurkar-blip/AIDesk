import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/user_model.dart';
import '../services/admin_service.dart';
import '../widgets/top_nav_bar.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<UserModel> _users = [];
  bool _isLoading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final list = await AdminService.getUsers();
    if (mounted) {
      setState(() {
        _users = list;
        _isLoading = false;
      });
    }
  }

  void _showRoleDialog(UserModel user) {
    String selectedRole = user.role;
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text('Modify Role: ${user.fullName}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select enterprise RBAC authorization tier:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    items: const [
                      DropdownMenuItem(value: 'REQUESTER', child: Text('REQUESTER (Read/Create Own Cases)')),
                      DropdownMenuItem(value: 'OPERATOR', child: Text('OPERATOR (Triage, Investigate, Resolve)')),
                      DropdownMenuItem(value: 'TEAM_LEAD', child: Text('TEAM_LEAD (Assign, Squad Oversight)')),
                      DropdownMenuItem(value: 'MANAGER', child: Text('MANAGER (Directorate SLAs & KPIs)')),
                      DropdownMenuItem(value: 'ADMIN', child: Text('ADMIN (Super Admin, RBAC, WORM Logs)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedRole = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final updated = await AdminService.updateUserRole(user.id, selectedRole);
                    if (mounted && updated != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Updated ${user.fullName} to $selectedRole'), backgroundColor: AppTheme.success),
                      );
                      _loadUsers();
                    }
                  },
                  child: const Text('Save Permissions'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _users.where((u) {
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        return u.fullName.toLowerCase().contains(q) || u.email.toLowerCase().contains(q) || u.role.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    final dateFormat = DateFormat('MMM d, yyyy');

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const TopNavBar(title: 'RBAC User Governance'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUsers,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('User Identity & Role Governance', style: Theme.of(context).textTheme.headlineMedium),
                            const SizedBox(height: 4),
                            const Text('Manage role permissions, assign IT squads, and audit active enterprise accounts.', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                          ],
                        ),
                        SizedBox(
                          width: 240,
                          height: 38,
                          child: TextField(
                            decoration: const InputDecoration(
                              hintText: 'Search user by name or email...',
                              prefixIcon: Icon(Icons.search, size: 16),
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (val) => setState(() => _search = val),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Enterprise Directory (${filtered.length} users)', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                                IconButton(icon: const Icon(Icons.refresh, size: 18), onPressed: _loadUsers),
                              ],
                            ),
                            const SizedBox(height: 14),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (ctx, idx) {
                                final u = filtered[idx];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: _getRoleColor(u.role).withValues(alpha: 0.15),
                                        child: Text(
                                          u.fullName.isNotEmpty ? u.fullName[0] : 'U',
                                          style: TextStyle(color: _getRoleColor(u.role), fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        flex: 3,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(u.fullName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                                            Text(u.email, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(u.teamName ?? 'General Support', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                      ),
                                      _buildRoleBadge(u.role),
                                      const SizedBox(width: 16),
                                      Text('Joined ${dateFormat.format(u.createdAt)}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                                      const SizedBox(width: 14),
                                      OutlinedButton.icon(
                                        onPressed: () => _showRoleDialog(u),
                                        icon: const Icon(Icons.security, size: 14),
                                        label: const Text('Edit Role', style: TextStyle(fontSize: 11)),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN': return const Color(0xFFDC2626);
      case 'MANAGER': return const Color(0xFF059669);
      case 'TEAM_LEAD': return const Color(0xFF7C3AED);
      case 'OPERATOR': return const Color(0xFF2563EB);
      default: return const Color(0xFF0284C7);
    }
  }

  Widget _buildRoleBadge(String role) {
    final color = _getRoleColor(role);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        role,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.4),
      ),
    );
  }
}
