enum AppErrorKind {
  network,
  unauthenticated,
  forbidden,
  notFound,
  conflict,
  validation,
  sessionChanged,
  unknown,
}

class AppError implements Exception {
  const AppError(this.kind, this.message, {this.code});

  final AppErrorKind kind;
  final String message;
  final String? code;

  bool get isRetryable => kind == AppErrorKind.network;
  bool get isAccessError =>
      kind == AppErrorKind.forbidden || kind == AppErrorKind.notFound;

  @override
  String toString() => message;
}
