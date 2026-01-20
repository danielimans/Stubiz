import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'role_router.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  bool loading = false;
  String errorText = '';

  Future<void> _resend() async {
    setState(() {
      loading = true;
      errorText = '';
    });

    try {
      await AuthService.resendActivationEmail();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification email sent. Please check inbox/spam.'),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => errorText = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _checkVerified() async {
    setState(() {
      loading = true;
      errorText = '';
    });

    try {
      final verified = await AuthService.reloadAndCheckEmailVerified();
      if (!mounted) return;

      if (!verified) {
        setState(
          () => errorText =
              'Not verified yet. Please click the link in your email.',
        );
        return;
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const RoleRouter()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) setState(() => errorText = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            const Text(
              'We have sent a verification link to your email.\n\n'
              'Please verify your email to activate your account.',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 14),

            if (errorText.isNotEmpty)
              Text(errorText, style: const TextStyle(color: Colors.red)),

            const Spacer(),

            ElevatedButton(
              onPressed: loading ? null : _checkVerified,
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text('I already verified'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: loading ? null : _resend,
              child: const Text('Resend verification email'),
            ),
          ],
        ),
      ),
    );
  }
}
