import 'package:ilox/expr.dart';
import 'package:ilox/ilox.dart';
import 'package:ilox/stmt.dart';
import 'package:ilox/token.dart';
import 'package:ilox/token_type.dart';

class Parser {
  final List<Token> tokens;
  final bool repl;
  int current = 0;

  Parser(this.tokens, this.repl);

  bool match(List<TokenType> types) {
    for (var type in types) {
      if (check(type)) {
        advance();
        return true;
      }
    }
    return false;
  }

  bool check(TokenType type) {
    if (isAtEnd()) return false;
    return peek().type == type;
  }

  Token advance() {
    if (!isAtEnd()) current++;
    return previous();
  }

  bool isAtEnd() {
    return peek().type == TokenType.EOF;
  }

  Token peek() {
    return tokens[current];
  }

  Token previous() {
    return tokens[current - 1];
  }

  List<Stmt> parse() {
    var statements = <Stmt>[];
    while (!isAtEnd()) {
      statements.add(declaration());
    }
    return statements;
  }

  Stmt declaration() {
    try {
      if (match([TokenType.VAR])) return varDeclaration();
      return statement();
    } on ParseError {
      synchronize();
      return null;
    }
  }

  Stmt varDeclaration() {
    var name = consume(TokenType.IDENTIFIER, 'Expect variable name.');
    Expr initializer;
    if (match([TokenType.EQUAL])) {
      initializer = expression();
    }
    consume(TokenType.SEMICOLON, "Expect ';' after variable declaration.");
    return Var(name, initializer);
  }

  Stmt statement() {
    if (match([TokenType.PRINT])) return printStatement();
    if (match([TokenType.LEFT_BRACE])) return Block(block());
    return expressionStatement();
  }

  Stmt printStatement() {
    var value = expression();
    consume(TokenType.SEMICOLON, "Expect ';' after value.");
    return Print(value);
  }

  List<Stmt> block() {
    var statements = <Stmt>[];
    while (!check(TokenType.RIGHT_BRACE) && !isAtEnd()) {
      statements.add(declaration());
    }
    consume(TokenType.RIGHT_BRACE, "Expect '}' after block.");
    return statements;
  }

  Stmt expressionStatement() {
    var expr = expression();
    if (repl && isAtEnd()) {
      // REPL should print expressions automatically
      return Print(expr);
    }
    consume(TokenType.SEMICOLON, "Expect ';' after expression.");
    return Expression(expr);
  }

  Expr expression() {
    return assignment();
  }

  Expr assignment() {
    var expr = equality();
    if (match([TokenType.EQUAL])) {
      var equals = previous();
      var value = assignment();
      if (expr is Variable) {
        var name = expr.name;
        return Assign(name, value);
      }
      error(equals, 'Invalid assignment target.');
    }
    return expr;
  }

  Expr equality() {
    var expr = comparison();
    while (match([TokenType.BANG_EQUAL, TokenType.EQUAL_EQUAL])) {
      var operator = previous();
      var right = comparison();
      expr = Binary(expr, operator, right);
    }
    return expr;
  }

  Expr comparison() {
    var expr = term();
    while (match([
      TokenType.GREATER,
      TokenType.GREATER_EQUAL,
      TokenType.LESS,
      TokenType.LESS_EQUAL
    ])) {
      var operator = previous();
      var right = term();
      expr = Binary(expr, operator, right);
    }
    return expr;
  }

  Expr term() {
    var expr = factor();
    while (match([TokenType.MINUS, TokenType.PLUS])) {
      var operator = previous();
      var right = factor();
      expr = Binary(expr, operator, right);
    }
    return expr;
  }

  Expr factor() {
    var expr = unary();
    while (match([TokenType.SLASH, TokenType.STAR])) {
      var operator = previous();
      var right = unary();
      expr = Binary(expr, operator, right);
    }
    return expr;
  }

  Expr unary() {
    if (match([TokenType.BANG, TokenType.MINUS])) {
      var operator = previous();
      var right = unary();
      return Unary(operator, right);
    }
    return primary();
  }

  Expr primary() {
    if (match([TokenType.FALSE])) return Literal(false);
    if (match([TokenType.TRUE])) return Literal(true);
    if (match([TokenType.NIL])) return Literal(null);

    if (match([TokenType.NUMBER, TokenType.STRING])) {
      return Literal(previous().literal);
    }

    if (match([TokenType.IDENTIFIER])) {
      return Variable(previous());
    }

    if (match([TokenType.LEFT_PAREN])) {
      var expr = expression();
      consume(TokenType.RIGHT_PAREN, "Expect ')' after expression.");
      return Grouping(expr);
    }

    throw error(peek(), 'Expect expression.');
  }

  Token consume(TokenType type, String message) {
    if (check(type)) return advance();
    throw error(peek(), message);
  }

  ParseError error(Token token, String message) {
    Lox.errorToken(token, message);
    return ParseError();
  }

  void synchronize() {
    advance();

    while (!isAtEnd()) {
      if (previous().type == TokenType.SEMICOLON) return;
      //ignore: missing_enum_constant_in_switch
      switch (peek().type) {
        case TokenType.CLASS:
        case TokenType.FUN:
        case TokenType.VAR:
        case TokenType.FOR:
        case TokenType.IF:
        case TokenType.WHILE:
        case TokenType.PRINT:
        case TokenType.RETURN:
          return;
      }
      advance();
    }
  }
}

class ParseError extends Error {}
