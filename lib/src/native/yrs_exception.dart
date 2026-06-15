/// Error thrown when the native yrs library reports a failed operation.
class YrsException implements Exception {
  /// Numeric error code returned by yffi.
  final int code;

  /// Operation that failed.
  final String operation;

  const YrsException(this.operation, this.code);

  @override
  String toString() => 'YrsException: $operation failed with code $code';
}
