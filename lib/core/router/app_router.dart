import 'package:go_router/go_router.dart';

import '../../features/auth/view/auth_views.dart';
import '../../features/notes/view/notes_views.dart';
import '../../features/onboarding/view/onboarding_view.dart';
import '../../features/profile/view/profile_view.dart';
import '../../features/scanner/view/scanner_views.dart';
import 'app_route_paths.dart';

class AppRouter {
  const AppRouter._();

  static final router = GoRouter(
    initialLocation: AppRoutePaths.onboarding,
    routes: [
      GoRoute(
        path: AppRoutePaths.onboarding,
        builder: (context, state) => const OnboardingView(),
      ),
      GoRoute(
        path: AppRoutePaths.login,
        builder: (context, state) => const LoginView(),
      ),
      GoRoute(
        path: AppRoutePaths.register,
        builder: (context, state) => const RegisterView(),
      ),
      GoRoute(
        path: AppRoutePaths.forgotPassword,
        builder: (context, state) => const ForgotPasswordView(),
      ),
      GoRoute(
        path: AppRoutePaths.otp,
        builder: (context, state) => const OtpView(),
      ),
      GoRoute(
        path: AppRoutePaths.resetPassword,
        builder: (context, state) => const ResetPasswordView(),
      ),
      GoRoute(
        path: AppRoutePaths.notes,
        builder: (context, state) => const NotesListView(),
      ),
      GoRoute(
        path: AppRoutePaths.addNote,
        builder: (context, state) => AddNoteView(
          initialContent: state.extra is String ? state.extra as String : null,
        ),
      ),
      GoRoute(
        path: AppRoutePaths.detailNote,
        builder: (context, state) =>
            NoteDetailView(noteId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutePaths.editNote,
        builder: (context, state) =>
            EditNoteView(noteId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutePaths.scanner,
        builder: (context, state) => const ScannerView(),
      ),
      GoRoute(
        path: AppRoutePaths.ocrResult,
        builder: (context, state) => const OcrResultView(),
      ),
      GoRoute(
        path: AppRoutePaths.profile,
        builder: (context, state) => const ProfileView(),
      ),
    ],
  );
}
