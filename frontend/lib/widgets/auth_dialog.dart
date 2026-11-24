import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class AuthDialog extends StatefulWidget {
  final AuthService authService;

  const AuthDialog({super.key, required this.authService});

  static Future<bool?> show(BuildContext context, AuthService authService) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AuthDialog(authService: authService),
    );
  }

  @override
  State<AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<AuthDialog> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoading) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Veuillez remplir tous les champs.');
      return;
    }
    if (password.length < 6) {
      setState(
        () => _errorMessage =
            'Le mot de passe doit comporter au moins 6 caractères.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isSignUp) {
        await widget.authService.register(email, password);
      } else {
        await widget.authService.login(email, password);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.cineColors;

    return Dialog(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: colors.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 410),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      color: colors.accent,
                      alignment: Alignment.center,
                      child: Icon(Icons.person_outline, color: colors.onAccent, size: 19),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _isSignUp ? 'Créer un compte' : 'Connexion CineBook',
                        style: TextStyle(
                          fontFamily: AppTheme.displayFont,
                          color: colors.textPrimary,
                          fontSize: 23,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Fermer la connexion',
                      icon: Icon(Icons.close, color: colors.textMuted, size: 19),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _isSignUp
                      ? 'Inscris-toi pour sauvegarder tes films et synchroniser ta Watchlist.'
                      : 'Connecte-toi pour sauvegarder et retrouver ta Watchlist. La découverte reste libre.',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 20),
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: colors.ruby.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: colors.ruby.withValues(alpha: 0.45)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: colors.ruby, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: colors.ruby,
                              fontSize: 11,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: colors.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Adresse Email',
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: colors.textMuted,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: TextStyle(color: colors.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Mot de passe (6 caractères min)',
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: colors.textMuted,
                      size: 18,
                    ),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 46,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.onAccent,
                            ),
                          )
                        : Text(_isSignUp ? 'S’INSCRIRE' : 'SE CONNECTER'),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _isSignUp = !_isSignUp;
                        _errorMessage = null;
                      });
                    },
                    child: Text(
                      _isSignUp
                          ? 'Déjà un compte ? Connecte-toi'
                          : 'Pas encore de compte ? Inscris-toi',
                      style: TextStyle(color: colors.accent, fontSize: 12),
                    ),
                  ),
                ),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      'Continuer sans compte',
                      style: TextStyle(color: colors.textMuted, fontSize: 11),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
