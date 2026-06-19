import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_route_paths.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/auth_service.dart';
import '../../../shared/widgets/logline_button.dart';
import '../../../shared/widgets/logline_text_field.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;

  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      await _authService.login(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (mounted) context.go(AppRoutePaths.notes);
    } on AuthException catch (error) {
      if (mounted) _showMessage(context, error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AuthFrame(
      title: 'Masuk ke LogLine',
      subtitle: 'Lanjutkan catatan dan logbook yang sudah tersinkron.',
      children: [
        LogLineTextField(
          label: 'Email',
          hint: 'nama@email.com',
          prefixIcon: Icons.mail_outline,
          controller: _emailController,
        ),
        const SizedBox(height: 18),
        LogLineTextField(
          label: 'Password',
          hint: 'Password',
          obscureText: true,
          prefixIcon: Icons.lock_outline,
          controller: _passwordController,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => context.go(AppRoutePaths.forgotPassword),
            child: const Text('Lupa password?'),
          ),
        ),
        const SizedBox(height: 10),
        LogLineButton(
          label: _loading ? 'Memproses...' : 'Masuk',
          onPressed: _loading ? null : _login,
        ),
        const SizedBox(height: 22),
        TextButton(
          onPressed: () => context.go(AppRoutePaths.register),
          child: const Center(child: Text('Belum punya akun? Daftar')),
        ),
      ],
    );
  }
}

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final AuthService _authService = AuthService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;

  Future<void> _register() async {
    setState(() => _loading = true);
    await _authService.register(
      name: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
    );
    if (mounted) context.go(AppRoutePaths.notes);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AuthFrame(
      title: 'Buat akun baru',
      subtitle: 'Mulai dari note pribadi, lalu undang tim saat perlu.',
      children: [
        LogLineTextField(
          label: 'Nama lengkap',
          hint: 'Ari Farhan',
          prefixIcon: Icons.person_outline,
          controller: _nameController,
        ),
        const SizedBox(height: 16),
        LogLineTextField(
          label: 'Email',
          hint: 'ari@email.com',
          prefixIcon: Icons.mail_outline,
          controller: _emailController,
        ),
        const SizedBox(height: 16),
        LogLineTextField(
          label: 'Password',
          hint: 'Minimal 8 karakter',
          obscureText: true,
          prefixIcon: Icons.lock_outline,
          controller: _passwordController,
        ),
        const SizedBox(height: 24),
        LogLineButton(
          label: _loading ? 'Mendaftarkan...' : 'Daftar',
          onPressed: _loading ? null : _register,
        ),
        const SizedBox(height: 18),
        TextButton(
          onPressed: () => context.go(AppRoutePaths.login),
          child: const Center(child: Text('Sudah punya akun? Masuk')),
        ),
      ],
    );
  }
}

class ForgotPasswordView extends StatelessWidget {
  const ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return _AuthFrame(
      showBack: true,
      title: 'Lupa password?',
      subtitle: 'Masukkan email akun. Kami akan mengirim kode verifikasi.',
      children: [
        const SizedBox(height: 32),
        const Icon(
          Icons.mark_email_read_outlined,
          size: 92,
          color: AppColors.primary,
        ),
        const SizedBox(height: 32),
        const LogLineTextField(label: 'Email', hint: 'nama@email.com'),
        const SizedBox(height: 24),
        LogLineButton(
          label: 'Kirim kode',
          onPressed: () => context.go(AppRoutePaths.otp),
        ),
        TextButton(
          onPressed: () => context.go(AppRoutePaths.login),
          child: const Center(child: Text('Kembali ke login')),
        ),
      ],
    );
  }
}

class OtpView extends StatelessWidget {
  const OtpView({super.key});

  @override
  Widget build(BuildContext context) {
    return _AuthFrame(
      showBack: true,
      title: 'Verifikasi kode',
      subtitle: 'Kode 4 digit sudah dikirim ke email kamu.',
      children: [
        const SizedBox(height: 48),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            '2',
            '4',
            '8',
            '1',
          ].map((n) => _OtpBox(number: n)).toList(),
        ),
        const SizedBox(height: 36),
        LogLineButton(
          label: 'Verifikasi',
          variant: LogLineButtonVariant.success,
          onPressed: () => context.go(AppRoutePaths.resetPassword),
        ),
        TextButton(
          onPressed: () {},
          child: const Center(child: Text('Kirim ulang dalam 00:24')),
        ),
      ],
    );
  }
}

class ResetPasswordView extends StatelessWidget {
  const ResetPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return _AuthFrame(
      showBack: true,
      title: 'Reset password',
      subtitle: 'Buat password baru agar semua logbook tetap aman.',
      children: [
        const SizedBox(height: 30),
        const LogLineTextField(
          label: 'Password baru',
          hint: 'Password baru',
          obscureText: true,
        ),
        const SizedBox(height: 16),
        const LogLineTextField(
          label: 'Konfirmasi password',
          hint: 'Konfirmasi password',
          obscureText: true,
        ),
        const SizedBox(height: 28),
        LogLineButton(
          label: 'Simpan password',
          onPressed: () => context.go(AppRoutePaths.login),
        ),
      ],
    );
  }
}

class _AuthFrame extends StatelessWidget {
  const _AuthFrame({
    required this.title,
    required this.subtitle,
    required this.children,
    this.showBack = false,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: showBack
          ? AppBar(
              leading: IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            )
          : null,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(28),
          children: [
            const Icon(
              Icons.note_alt_rounded,
              color: AppColors.primary,
              size: 46,
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(fontSize: 29, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(color: AppColors.muted, height: 1.4),
            ),
            const SizedBox(height: 34),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({required this.number});

  final String number;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 66,
      height: 66,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: number == '8' ? AppColors.primary : AppColors.border,
        ),
      ),
      child: Text(
        number,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
      ),
    );
  }
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
