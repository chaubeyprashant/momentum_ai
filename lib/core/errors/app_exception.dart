/// Base application exception.
class AppException implements Exception {
  const AppException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => 'AppException: $message';
}

class NetworkException extends AppException {
  const NetworkException(super.message, {super.code});
}

class AiServiceException extends AppException {
  const AiServiceException(super.message, {super.code});
}

class StorageException extends AppException {
  const StorageException(super.message, {super.code});
}

class AuthException extends AppException {
  const AuthException(super.message, {super.code});
}
