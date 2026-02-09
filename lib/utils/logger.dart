import 'dart:developer' as developer;

class AppLogger {
  static const String _tag = 'AirplaneScheduler';

  static void i(String message) {
    developer.log('ℹ️ $message', name: _tag);
  }

  static void d(String message) {
    developer.log('🐛 $message', name: _tag);
  }

  static void w(String message) {
    developer.log('⚠️ $message', name: _tag);
  }

  static void e(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      '❌ $message',
      name: _tag,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
