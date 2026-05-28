class AppConfig {
  const AppConfig._();

  static const mongodbUri = String.fromEnvironment('MONGODB_URI');
  static const mongodbDatabase = String.fromEnvironment(
    'MONGODB_DATABASE',
    defaultValue: 'logline',
  );

  static bool get hasMongoConfig => mongodbUri.trim().isNotEmpty;
}
