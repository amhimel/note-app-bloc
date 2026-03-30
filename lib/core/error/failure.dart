abstract class Failure {
  final String message;
  const Failure(this.message);
}

// Local database (Hive)  error
class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Local data operation failed']);
}

// Note Not found error
class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Note not found']);
}

// Any other unexpected error
class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'Something went wrong']);
}
