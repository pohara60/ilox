import 'package:ilox/token_type.dart';

class Token {
  final String lexeme;
  final TokenType type;
  final Object literal;
  final int line;

  Token(this.type, this.lexeme, this.literal, this.line);

  @override
  String toString() {
    return '$type $lexeme $literal';
  }
}
