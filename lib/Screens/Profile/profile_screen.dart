import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../Controllers/payment_controller.dart';
import '../../Controllers/auth_controller.dart';
import '../../Controllers/notification_controller.dart';
import '../../Controllers/theme_controller.dart';
import '../../Controllers/wishlist_controller.dart';
import '../../Utils/app_theme.dart';
import '../Authentication/Views/splash_screen.dart';
import '../Notifications/notifications_screen.dart';
import '../Wishlist/wishlist_screen.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';
import 'saved_addresses_screen.dart';
import 'saved_cards_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _uploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<AuthController>().fetchUserProfile();
      context.read<PaymentController>().fetchSavedCards();
    });
  }

  Future<void> _pickProfilePicture() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 80,
    );
    if (picked == null || !mounted) return;

    // Read the bytes so the upload works on every platform (on web the picked
    // path is a blob URL that dart:io File cannot read).
    final bytes = await picked.readAsBytes();
    if (!mounted) return;

    setState(() => _uploadingPhoto = true);
    final auth = context.read<AuthController>();
    final ok = await auth.updateProfilePicture(bytes);
    if (!mounted) return;
    setState(() => _uploadingPhoto = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Profile picture updated.'
            : (auth.error ?? 'Failed to update picture.')),
        backgroundColor: ok ? AppTheme.successColor : AppTheme.errorColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: Consumer<AuthController>(
        builder: (context, auth, _) {
          final savedCardsCount = context.watch<PaymentController>().savedCards.length;
          final email = auth.user?.email ?? '';
          final name = auth.userName.isNotEmpty ? auth.userName : 'User';
          final initials = _initials(name);

          return ListView(
            children: [
              // ── Avatar header ──
              Container(
                padding: const EdgeInsets.symmetric(vertical: 32),
                color: AppTheme.primaryColor,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _uploadingPhoto ? null : _pickProfilePicture,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.2),
                            backgroundImage: auth.photoUrl.isNotEmpty
                                ? NetworkImage(auth.photoUrl)
                                : null,
                            child: _uploadingPhoto
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : (auth.photoUrl.isEmpty
                                    ? Text(
                                        initials,
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      )
                                    : null),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.primaryColor,
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 16,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // ── Account section ──
              _SectionLabel('Account'),
              _MenuItem(
                icon: Icons.person_outline,
                label: 'Edit Profile',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                ),
              ),
              _MenuItem(
                icon: Icons.lock_outline,
                label: 'Change Password',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ChangePasswordScreen()),
                ),
              ),
              _MenuItem(
                icon: Icons.location_on_outlined,
                label: 'Saved Addresses',
                subtitle: '${auth.addresses.length} saved',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SavedAddressesScreen()),
                ),
              ),
              _MenuItem(
                icon: Icons.credit_card_outlined,
                label: 'Saved Cards',
                subtitle: '$savedCardsCount saved',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SavedCardsScreen()),
                ),
              ),

              const SizedBox(height: 8),

              // ── Shopping section ──
              _SectionLabel('Shopping'),
              _MenuItem(
                icon: Icons.favorite_outline,
                label: 'Wishlist',
                subtitle: '${context.watch<WishlistController>().count} saved',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WishlistScreen()),
                ),
              ),
              _MenuItem(
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                subtitle: context.watch<NotificationController>().unreadCount > 0
                    ? '${context.watch<NotificationController>().unreadCount} unread'
                    : null,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                ),
              ),

              const SizedBox(height: 8),

              // ── Preferences section ──
              _SectionLabel('Preferences'),
              Consumer<ThemeController>(
                builder: (context, themeCtrl, _) {
                  return SwitchListTile(
                    secondary: Icon(
                      themeCtrl.isDarkMode
                          ? Icons.dark_mode_outlined
                          : Icons.light_mode_outlined,
                      color: AppTheme.textPrimaryColor,
                    ),
                    title: const Text('Dark Mode'),
                    subtitle: Text(themeCtrl.isDarkMode ? 'On' : 'Off'),
                    value: themeCtrl.isDarkMode,
                    onChanged: (_) => themeCtrl.toggleTheme(),
                  );
                },
              ),

              const SizedBox(height: 8),

              // ── Logout section ──
              _SectionLabel('Session'),
              _MenuItem(
                icon: Icons.logout,
                label: 'Logout',
                color: AppTheme.errorColor,
                onTap: () => _confirmLogout(context, auth),
              ),
            ],
          );
        },
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Future<void> _confirmLogout(
      BuildContext context, AuthController auth) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await auth.logout();
      if (context.mounted) {
        context.read<WishlistController>().reset();
        context.read<NotificationController>().reset();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const SplashScreen(
              loadingMessage: 'Logging out...',
              duration: Duration(seconds: 2),
            ),
          ),
          (route) => false,
        );
      }
    }
  }
}

// ──────────────────────────────────────────────
// Shared sub-widgets
// ──────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: Colors.grey.shade500,
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? color;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tileColor = color ?? AppTheme.textPrimaryColor;
    return ListTile(
      leading: Icon(icon, color: tileColor),
      title: Text(label, style: TextStyle(color: tileColor)),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
      onTap: onTap,
    );
  }
}
