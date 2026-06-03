import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/app_snackbar.dart';
import '../../l10n/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _identifierError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _identifierController.addListener(() {
      if (_identifierError != null) setState(() => _identifierError = null);
    });
    _passwordController.addListener(() {
      if (_passwordError != null) setState(() => _passwordError = null);
    });
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;

    String? idErr;
    String? pwErr;
    if (identifier.isEmpty) idErr = 'Введите email или номер студента';
    if (password.isEmpty) pwErr = 'Введите пароль';

    if (idErr != null || pwErr != null) {
      setState(() {
        _identifierError = idErr;
        _passwordError = pwErr;
      });
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      await auth.login(identifier, password);
      if (!mounted) return;
      TextInput.finishAutofillContext(shouldSave: true);
    } catch (e) {
      AppSnackbar.showError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final l = AppLocalizations.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.primaryColor.withValues(alpha: 0.8),
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Icon(Icons.school_outlined, size: 50, color: theme.primaryColor),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    l.loginWelcomeBack,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: themeProvider.themeType == AppThemeType.darkGold || themeProvider.themeType == AppThemeType.darkEmerald
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l.loginSubtitle,
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 50),
                  AutofillGroup(
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _identifierController,
                          hint: l.loginEmailOrId,
                          icon: Icons.person_outline,
                          autofillHints: const [AutofillHints.username, AutofillHints.email],
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.emailAddress,
                          errorText: _identifierError,
                          theme: theme,
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _passwordController,
                          hint: l.loginPassword,
                          icon: Icons.lock_outline,
                          obscure: _obscurePassword,
                          autofillHints: const [AutofillHints.password],
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _handleLogin(),
                          errorText: _passwordError,
                          theme: theme,
                          suffix: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 20),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: Text(l.loginForgotPassword, style: TextStyle(color: theme.primaryColor)),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      return SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: auth.isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            elevation: 5,
                          ),
                          child: auth.isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(l.loginButton, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    List<String>? autofillHints,
    TextInputAction? textInputAction,
    TextInputType? keyboardType,
    ValueChanged<String>? onSubmitted,
    bool obscure = false,
    Widget? suffix,
    String? errorText,
    required ThemeData theme,
  }) {
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: hasError
                ? Colors.red.withValues(alpha: 0.06)
                : theme.cardColor.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: hasError ? Colors.red.shade400 : Colors.white10,
              width: hasError ? 1.5 : 1,
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            autofillHints: autofillHints,
            textInputAction: textInputAction,
            keyboardType: keyboardType,
            onSubmitted: onSubmitted,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(
                icon,
                color: hasError ? Colors.red.shade400 : theme.primaryColor,
                size: 22,
              ),
              suffixIcon: suffix,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.error_outline, size: 13, color: Colors.red.shade400),
              const SizedBox(width: 4),
              Text(
                errorText,
                style: TextStyle(color: Colors.red.shade400, fontSize: 12),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
