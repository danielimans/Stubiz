import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../auth/role_router.dart';
import '../../widgets/auth_widgets.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();

  bool hidePass = true;
  bool loading = false;
  String errorText = '';

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    setState(() {
      loading = true;
      errorText = '';
    });

    try {
      final name = nameCtrl.text.trim();
      final email = emailCtrl.text.trim();
      final pass = passCtrl.text;
      final confirm = confirmCtrl.text;

      if (name.isEmpty || email.isEmpty || pass.isEmpty || confirm.isEmpty) {
        throw Exception('Please fill in all fields.');
      }
      if (pass != confirm) {
        throw Exception('Passwords do not match.');
      }
      if (pass.length < 6) {
        throw Exception('Password must be at least 6 characters.');
      }

      // Register user
      await AuthService.registerEmailPassword(
        displayName: name,
        email: email,
        password: pass,
      );

      if (!mounted) return;

      // Skip email verification and go directly to RoleRouter
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const RoleRouter()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        setState(() => errorText = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
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
                  title: 'Get On Board!',
                  subtitle: 'Create your profile to start your journey.',
                ),
                const SizedBox(height: 16),

                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5E5E5)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.school_outlined,
                        size: 20,
                        color: Colors.black54,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Student',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                RoundedField(
                  controller: nameCtrl,
                  hint: 'Full Name',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 12),

                RoundedField(
                  controller: emailCtrl,
                  hint: 'E-Mail',
                  icon: Icons.email_outlined,
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
                      color: Colors.black54,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                RoundedField(
                  controller: confirmCtrl,
                  hint: 'Confirm Password',
                  icon: Icons.lock_outline,
                  obscure: true,
                ),

                if (errorText.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    errorText,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ],

                const SizedBox(height: 12),
                PrimaryButton(
                  text: 'Signup',
                  onPressed: loading ? null : _signup,
                  loading: loading,
                ),

                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an Account? ',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    GestureDetector(
                      onTap: loading ? null : () => Navigator.pop(context),
                      child: const Text(
                        'Login',
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