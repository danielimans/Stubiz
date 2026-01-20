import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../profile/favourites_page.dart';
import '../auth/login_page.dart';
import 'my_listings_page.dart';
import 'my_exchanges_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) {
    return _db.collection('users').doc(uid);
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
            child: const Text('Go to Login'),
          ),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _userDoc(user.uid).snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data();

        final displayName =
            ((data?['displayName'] as String?)?.trim().isNotEmpty == true)
            ? (data!['displayName'] as String)
            : ((user.displayName?.trim().isNotEmpty == true)
                  ? user.displayName!
                  : 'Student');

        final email = (data?['email'] as String?) ?? (user.email ?? '');
        final role = (data?['role'] as String?) ?? 'student';
        final emailVerified =
            (data?['emailVerified'] as bool?) ?? user.emailVerified;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Settings coming soon')),
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 45,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: const Icon(
                    Icons.person,
                    size: 45,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),

                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(email, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _chip(
                      icon: Icons.badge_outlined,
                      text: role.toLowerCase() == 'admin' ? 'Admin' : 'Student',
                    ),
                    _chip(
                      icon: emailVerified
                          ? Icons.verified_outlined
                          : Icons.error_outline,
                      text: emailVerified ? 'Verified' : 'Not Verified',
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.store),
                        title: const Text('My Listings'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MyListingsPage(),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.swap_horiz),
                        title: const Text('My Exchanges'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MyExchangesPage(),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.edit),
                        title: const Text('Edit Profile'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          await _editDisplayName(
                            currentName: displayName,
                            uid: user.uid,
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.favorite),
                        title: const Text('My Favorites'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const FavoritesPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                ElevatedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _confirmLogout,
                ),

                if (snap.connectionState == ConnectionState.waiting) ...[
                  const SizedBox(height: 16),
                  const LinearProgressIndicator(),
                ],
                if (snap.hasError) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load profile: ${snap.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (snap.hasData && !snap.data!.exists) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Profile document not found in Firestore.\n(Register should create users/{uid}.)',
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _chip({required IconData icon, required String text}) {
    return Chip(avatar: Icon(icon, size: 18), label: Text(text));
  }

  Future<void> _editDisplayName({
    required String currentName,
    required String uid,
  }) async {
    final ctrl = TextEditingController(text: currentName);
    bool saving = false;
    String err = '';

    await showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (dialogCtx, setStateDialog) {
            return AlertDialog(
              title: const Text('Edit Profile'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: ctrl,
                    decoration: const InputDecoration(
                      labelText: 'Display Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (err.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(err, style: const TextStyle(color: Colors.red)),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final newName = ctrl.text.trim();
                          if (newName.isEmpty) {
                            setStateDialog(() => err = 'Name cannot be empty.');
                            return;
                          }

                          setStateDialog(() {
                            saving = true;
                            err = '';
                          });

                          try {
                            final user = AuthService.currentUser;
                            if (user != null) {
                              await user.updateDisplayName(newName);
                            }

                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(uid)
                                .update({
                                  'displayName': newName,
                                  'updatedAt': FieldValue.serverTimestamp(),
                                });

                            // FIX: do NOT use dialogCtx after await unless dialogCtx is mounted
                            if (!dialogCtx.mounted) return;
                            Navigator.pop(dialogCtx);

                            if (!mounted) return;
                            _showSnack('Profile updated.');
                          } catch (e) {
                            setStateDialog(() => err = e.toString());
                          } finally {
                            setStateDialog(() => saving = false);
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    ctrl.dispose();
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await AuthService.logout();

                // FIX: close dialog using dialogCtx and check it is mounted
                if (dialogCtx.mounted) {
                  Navigator.pop(dialogCtx);
                }

                // FIX: then use State.context only if mounted
                if (!mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showSnack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}
