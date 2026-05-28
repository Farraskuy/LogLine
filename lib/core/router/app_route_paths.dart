class AppRoutePaths {
  const AppRoutePaths._();

  static const onboarding = '/';
  static const login = '/auth/login';
  static const register = '/auth/register';
  static const forgotPassword = '/auth/forgot-password';
  static const otp = '/auth/otp';
  static const resetPassword = '/auth/reset-password';
  static const notes = '/notes';
  static const addNote = '/notes/add';
  static const detailNote = '/notes/:id';
  static const editNote = '/notes/:id/edit';
  static const scanner = '/scanner';
  static const ocrResult = '/scanner/result';
  static const collaborators = '/notes/collaborators';
  static const profile = '/profile';

  static String noteDetail(String id) => '/notes/$id';
  static String noteEdit(String id) => '/notes/$id/edit';
}
