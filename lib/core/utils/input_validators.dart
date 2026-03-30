
class InputValidators {
  /// Validates note title
  /// Returns null if valid, error message if invalid
  static String? validateTitle(String? title) {
    if (title == null || title.trim().isEmpty) {
      return 'Title is required';
    }
    if (title.length > 100) {
      return 'Title must be less than 100 characters';
    }
    return null;
  }

  /// Validates note description
  /// Returns null if valid, error message if invalid
  static String? validateDescription(String? description) {
    if (description != null && description.length > 500) {
      return 'Description must be less than 500 characters';
    }
    return null;
  }
}
