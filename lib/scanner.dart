import 'package:ilox/ilox.dart';
import 'package:ilox/token.dart';
import 'package:ilox/token_type.dart';

class Scanner {
  static final Map<String, TokenType> keywords = {
    'and': TokenType.AND,
    'class': TokenType.CLASS,
    'else': TokenType.ELSE,
    'false': TokenType.FALSE,
    'for': TokenType.FOR,
    'fun': TokenType.FUN,
    'if': TokenType.IF,
    'nil': TokenType.NIL,
    'or': TokenType.OR,
    'print': TokenType.PRINT,
    'return': TokenType.RETURN,
    'super': TokenType.SUPER,
    'this': TokenType.THIS,
    'true': TokenType.TRUE,
    'var': TokenType.VAR,
    'while': TokenType.WHILE,
    'break': TokenType.BREAK,
    'continue': TokenType.CONTINUE,
  };

  final String source;
  final List<Token> tokens = <Token>[];
  int start = 0;
  int current = 0;
  int line = 1;

  Scanner(this.source);

  List<Token> scanTokens() {
    while (!isAtEnd()) {
      // We are at the beginning of the next lexeme.
      start = current;
      scanToken();
    }

    tokens.add(Token(TokenType.EOF, '', null, line));
    return tokens;
  }

  bool isAtEnd() {
    return current >= source.length;
  }

  String advance() {
    return source[current++];
  }

  bool match(String expected) {
    if (isAtEnd()) return false;
    if (source[current] != expected) return false;

    current++;
    return true;
  }

  String peek() {
    if (isAtEnd()) return '';
    return source[current];
  }

  String peekNext() {
    if (current + 1 >= source.length) return '';
    return source[current + 1];
  }

  void addToken(TokenType type, [Object literal]) {
    var text = source.substring(start, current);
    tokens.add(Token(type, text, literal, line));
  }

  void scanToken() {
    var c = advance();
    switch (c) {
      case '(':
        addToken(TokenType.LEFT_PAREN);
        break;
      case ')':
        addToken(TokenType.RIGHT_PAREN);
        break;
      case '{':
        addToken(TokenType.LEFT_BRACE);
        break;
      case '}':
        addToken(TokenType.RIGHT_BRACE);
        break;
      case ',':
        addToken(TokenType.COMMA);
        break;
      case '.':
        addToken(TokenType.DOT);
        break;
      case '-':
        addToken(TokenType.MINUS);
        break;
      case '+':
        addToken(TokenType.PLUS);
        break;
      case ';':
        addToken(TokenType.SEMICOLON);
        break;
      case '*':
        addToken(TokenType.STAR);
        break;
      case '!':
        addToken(match('=') ? TokenType.BANG_EQUAL : TokenType.BANG);
        break;
      case '=':
        addToken(match('=') ? TokenType.EQUAL_EQUAL : TokenType.EQUAL);
        break;
      case '<':
        addToken(match('=') ? TokenType.LESS_EQUAL : TokenType.LESS);
        break;
      case '>':
        addToken(match('=') ? TokenType.GREATER_EQUAL : TokenType.GREATER);
        break;
      case '/':
        if (match('/')) {
          // A comment goes until the end of the line.
          while (peek() != '\n' && !isAtEnd()) {
            advance();
          }
        } else {
          addToken(TokenType.SLASH);
        }
        break;
      case ' ':
      case '\r':
      case '\t':
        // Ignore whitespace.
        break;

      case '\n':
        line++;
        break;
      case '"':
        string();
        break;
      default:
        if (isDigit(c)) {
          number();
        } else if (isAlpha(c)) {
          identifier();
        } else {
          Lox.error(line, 'Unexpected character.');
        }
        break;
    }
  }

  void string() {
    while (peek() != '"' && !isAtEnd()) {
      if (peek() == '\n') line++;
      advance();
    }

    if (isAtEnd()) {
      Lox.error(line, 'Unterminated string.');
      return;
    }

    // The closing '.
    advance();

    // Trim the surrounding quotes.
    var value = source.substring(start + 1, current - 1);
    addToken(TokenType.STRING, value);
  }

  bool isDigit(String c) {
    return c.compareTo('0') >= 0 && c.compareTo('9') <= 0;
  }

  void number() {
    while (isDigit(peek())) {
      advance();
    }

    // Look for a fractional part.
    if (peek() == '.' && isDigit(peekNext())) {
      // Consume the '.'
      advance();
      while (isDigit(peek())) {
        advance();
      }
    }

    addToken(
        TokenType.NUMBER, double.parse((source.substring(start, current))));
  }

  bool isAlpha(String c) {
    return (c.compareTo('a') >= 0 && c.compareTo('z') <= 0) ||
        (c.compareTo('A') >= 0 && c.compareTo('Z') <= 0) ||
        c == '_';
  }

  bool isAlphaNumeric(String c) {
    return isAlpha(c) || isDigit(c);
  }

  void identifier() {
    while (isAlphaNumeric(peek())) {
      advance();
    }
    var text = source.substring(start, current);
    var type = keywords[text];
    addToken(type ?? TokenType.IDENTIFIER);
  }
}
