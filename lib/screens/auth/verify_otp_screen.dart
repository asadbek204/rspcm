import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String email;
  const VerifyOtpScreen({super.key, required this.email});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _codeController = TextEditingController();
  bool _isResending = false;

  Future<void> _handleVerify() async {
    if (_codeController.text.isEmpty) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.verifyOtp(widget.email, _codeController.text);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Подтверждение успешно. Теперь можно войти.')),
        );
        Navigator.popUntil(context, (route) => route.isFirst);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Неверный код. Попробуйте еще раз.')),
        );
      }
    }
  }

  Future<void> _handleResend() async {
    setState(() => _isResending = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.resendOtp(widget.email);
    if (mounted) {
      setState(() => _isResending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Код подтверждения отправлен повторно.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Подтверждение email')),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mark_email_read_outlined, size: 80, color: Colors.blue),
            const SizedBox(height: 30),
            const Text(
              'Введите код, отправленный на',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            Text(
              widget.email,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 10, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: '000000',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                filled: true,
                fillColor: theme.cardColor.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 40),
            Consumer<AuthProvider>(
              builder: (context, auth, _) {
                return SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : _handleVerify,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: auth.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Подтвердить', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: _isResending ? null : _handleResend,
              child: Text(_isResending ? 'Отправка...' : 'Отправить код повторно'),
            ),
          ],
        ),
      ),
    );
  }
}
