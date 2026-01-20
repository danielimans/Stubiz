import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import 'register_page.dart';
import 'role_router.dart';
import '../../widgets/auth_widgets.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  bool hidePass = true;
  bool loading = false;
  String errorText = '';

  String role = 'student'; // student/admin selection required

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      loading = true;
      errorText = '';
    });

    try {
      await AuthService.loginEmailPassword(
        email: emailCtrl.text,
        password: passCtrl.text,
        expectedRole: role,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RoleRouter()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => errorText = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // FIXED: dialog only collects email, async happens AFTER dialog closes
  Future<void> _showForgotPasswordDialog() async {
    final email = await showDialog<String>(
      context: context,
      builder: (_) =>
          _ForgotPasswordDialog(initialEmail: emailCtrl.text.trim()),
    );

    if (!mounted) return;
    if (email == null) return; // cancelled

    setState(() {
      loading = true;
      errorText = '';
    });

    try {
      await AuthService.sendResetPasswordEmail(email);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reset link sent. Check your email.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              children: [
                const SizedBox(height: 10),
                const AuthHeader(
                  title: 'Welcome Back,',
                  subtitle: 'Make it work, make it right, make it fast.',
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  initialValue: role,
                  items: const [
                    DropdownMenuItem(value: 'student', child: Text('Student')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  ],
                  onChanged: (v) => setState(() => role = v ?? 'student'),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                RoundedField(
                  controller: emailCtrl,
                  hint: 'E-Mail',
                  icon: Icons.person_outline,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),

                RoundedField(
                  controller: passCtrl,
                  hint: 'Password',
                  icon: Icons.lock_outline,
                  obscure: hidePass,
                  suffix: IconButton(
                    onPressed: () => setState(() => hidePass = !hidePass),
                    icon: Icon(
                      hidePass ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),

                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: loading ? null : _showForgotPasswordDialog,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      foregroundColor: const Color(0xFF6C63FF),
                    ),
                    child: const Text(
                      'Forget Password?',
                      style: TextStyle(fontSize: 12.5),
                    ),
                  ),
                ),

                if (errorText.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(errorText, style: const TextStyle(color: Colors.red)),
                ],

                const SizedBox(height: 10),
                PrimaryButton(
                  text: 'Login',
                  onPressed: _login,
                  loading: loading,
                ),

                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an Account? ",
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    GestureDetector(
                      onTap: loading
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RegisterPage(),
                                ),
                              );
                            },
                      child: const Text(
                        'Signup',
                        style: TextStyle(
                          color: Color(0xFF1A73E8),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ForgotPasswordDialog extends StatefulWidget {
  final String initialEmail;
  const _ForgotPasswordDialog({required this.initialEmail});

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  late final TextEditingController _ctrl;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final email = _ctrl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Please enter your email.');
      return;
    }
    Navigator.of(context).pop(email);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Forgot Password'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RoundedField(
            controller: _ctrl,
            hint: 'E-Mail',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          if (_error.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(_error, style: const TextStyle(color: Colors.red)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('Send')),
      ],
    );
  }
}
