import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_screens.dart';
import '../../features/notes/presentation/notes_screens.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/scanner/presentation/scanner_screens.dart';
import 'app_route_paths.dart';

class AppRouter {
  const AppRouter._();

  static final router = GoRouter(
    initialLocation: AppRoutePaths.onboarding,
    routes: [
      GoRoute(
        path: AppRoutePaths.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.otp,
        builder: (context, state) => const OtpScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.resetPassword,
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.notes,
        builder: (context, state) => const NotesListScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.addNote,
        builder: (context, state) => const AddNoteScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.detailNote,
        builder: (context, state) =>
            NoteDetailScreen(noteId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutePaths.editNote,
        builder: (context, state) =>
            EditNoteScreen(noteId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutePaths.scanner,
        builder: (context, state) => const ScannerScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.ocrResult,
        builder: (context, state) => const OcrResultScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
}
