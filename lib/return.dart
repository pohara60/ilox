class ReturnException implements Exception {
  final Object value;

  ReturnException(this.value);

  @override
  String toString() => "Return ${value ?? 'nil'}";
}
