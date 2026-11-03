/// Errors raised by the data and service layers.
///
/// [AppException.message] is always safe to show to the user.
sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Input failed validation. [fieldErrors] maps field names to messages so
/// forms can show them inline.
final class ValidationException extends AppException {
  const ValidationException(super.message, {this.fieldErrors = const {}});

  ValidationException.field(String field, super.message) : fieldErrors = {field: message};

  final Map<String, String> fieldErrors;
}

final class NotFoundException extends AppException {
  NotFoundException(String entity, String id) : super('$entity not found ($id)');
}

/// Converts any thrown value into a message suitable for a toast.
String errorMessage(Object error, {String fallback = 'Something went wrong'}) {
  if (error is AppException) return error.message;
  return fallback;
}
