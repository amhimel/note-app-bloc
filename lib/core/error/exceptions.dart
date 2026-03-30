
abstract class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;
}

/// Database exceptions
class DatabaseException extends AppException {
  const DatabaseException([super.message = 'Database error occurred']);
}

/// Cache exceptions
class CacheException extends AppException {
  const CacheException([super.message = 'Cache error occurred']);
}
