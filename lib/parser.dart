import 'package:ilox/expr.dart';
import 'package:ilox/ilox.dart';
import 'package:ilox/stmt.dart';
import 'package:ilox/token.dart';
import 'package:ilox/token_type.dart';

class Parser {
  final List<Token> tokens;
  final bool repl;
  int current = 0;
  int loopDepth = 0;

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

  bool check2(TokenType type) {
    if (isAtEnd()) return false;
    return peek2().type == type;
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

  Token peek2() {
    return tokens[current + 1];
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
      if (match([TokenType.CLASS])) return classDeclaration();
      if (check(TokenType.FUN) && check2(TokenType.IDENTIFIER)) {
        match([TokenType.FUN]);
        return function('function');
      }
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

  Stmt classDeclaration() {
    var name = consume(TokenType.IDENTIFIER, 'Expect class name.');
    Variable superclass;
    if (match([TokenType.LESS])) {
      consume(TokenType.IDENTIFIER, 'Expect superclass name.');
      superclass = Variable(previous());
    }
    consume(TokenType.LEFT_BRACE, "Expect '{' before class body.");
    var methods = <Func>[];
    var functions = <Func>[];
    while (!check(TokenType.RIGHT_BRACE) && !isAtEnd()) {
      if (match([TokenType.FUN])) {
        functions.add(function('function'));
        continue;
      }
      methods.add(function('method'));
    }
    consume(TokenType.RIGHT_BRACE, "Expect '}' after class body.");
    return Class(name, superclass, methods, functions);
  }

  Func function(String kind) {
    var name = consume(TokenType.IDENTIFIER, 'Expect $kind name.');
    consume(TokenType.LEFT_PAREN, "Expect '(' after $kind name.");
    var parameters = parameterList();
    consume(TokenType.LEFT_BRACE, "Expect '{' before $kind body.");
    var body = block();
    return Func(name, parameters, body);
  }

  List<Token> parameterList() {
    var parameters = <Token>[];
    if (!check(TokenType.RIGHT_PAREN)) {
      do {
        if (parameters.length >= 255) {
          error(peek(), "Can't have more than 255 parameters.");
        }
        parameters.add(consume(TokenType.IDENTIFIER, 'Expect parameter name.'));
      } while (match([TokenType.COMMA]));
    }
    consume(TokenType.RIGHT_PAREN, "Expect ')' after parameters.");
    return parameters;
  }

  Stmt statement() {
    if (match([TokenType.PRINT])) return printStatement();
    if (match([TokenType.RETURN])) return returnStatement();
    if (match([TokenType.IF])) return ifStatement();
    if (match([TokenType.WHILE])) return whileStatement();
    if (match([TokenType.BREAK])) return breakStatement();
    if (match([TokenType.CONTINUE])) return continueStatement();
    if (match([TokenType.FOR])) return forStatement();
    if (match([TokenType.LEFT_BRACE])) return Block(block());
    return expressionStatement();
  }

  Stmt printStatement() {
    var value = expression();
    consume(TokenType.SEMICOLON, "Expect ';' after value.");
    return Print(value);
  }

  Stmt returnStatement() {
    var keyword = previous();
    Expr value;
    if (!check(TokenType.SEMICOLON)) {
      value = expression();
    }
    consume(TokenType.SEMICOLON, "Expect ';' after return value.");
    return Return(keyword, value);
  }

  Stmt ifStatement() {
    consume(TokenType.LEFT_PAREN, "Expect '(' after 'if'.");
    var condition = expression();
    consume(TokenType.RIGHT_PAREN, "Expect ')' after if condition.");
    var thenBranch = statement();
    Stmt elseBranch;
    if (match([TokenType.ELSE])) {
      elseBranch = statement();
    }
    return If(condition, thenBranch, elseBranch);
  }

  Stmt whileStatement() {
    loopDepth++;
    consume(TokenType.LEFT_PAREN, "Expect '(' after 'while'.");
    var condition = expression();
    consume(TokenType.RIGHT_PAREN, "Expect ')' after condition.");
    var body = statement();
    loopDepth--;
    return While(condition, body);
  }

  Stmt breakStatement() {
    if (loopDepth == 0) {
      throw error(previous(), 'Break can only appear in while/for block.');
    }
    consume(TokenType.SEMICOLON, "Expect ';' after break.");
    return Break();
  }

  Stmt continueStatement() {
    if (loopDepth == 0) {
      throw error(previous(), 'Continue can only appear in while/for block.');
    }
    consume(TokenType.SEMICOLON, "Expect ';' after continue.");
    return Continue();
  }

  Stmt forStatement() {
    loopDepth++;
    consume(TokenType.LEFT_PAREN, "Expect '(' after 'for'.");
    Stmt initializer;
    if (match([TokenType.SEMICOLON])) {
      initializer = null;
    } else if (match([TokenType.VAR])) {
      initializer = varDeclaration();
    } else {
      initializer = expressionStatement();
    }
    Expr condition;
    if (!check(TokenType.SEMICOLON)) {
      condition = expression();
    }
    consume(TokenType.SEMICOLON, "Expect ';' after loop condition.");
    Expr increment;
    if (!check(TokenType.RIGHT_PAREN)) {
      increment = expression();
    }
    consume(TokenType.RIGHT_PAREN, "Expect ')' after for clauses.");
    var body = statement();
    loopDepth--;

    // Desugaring - construct while statement to implement for statement
    if (increment != null) {
      body = Block([
        body,
        Expression(increment),
      ]);
      body = While(condition ?? Literal(true), body);
    }
    if (initializer != null) {
      body = Block([initializer, body]);
    }
    return body;
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
    var expr = or();
    if (match([TokenType.EQUAL])) {
      var equals = previous();
      var value = assignment();
      if (expr is Variable) {
        var name = expr.name;
        return Assign(name, value);
      } else if (expr is Get) {
        var get = expr;
        return Set(get.object, get.name, value);
      }
      error(equals, 'Invalid assignment target.');
    }
    return expr;
  }

  Expr or() {
    var expr = and();
    while (match([TokenType.OR])) {
      var operator = previous();
      var right = and();
      expr = Logical(expr, operator, right);
    }
    return expr;
  }

  Expr and() {
    var expr = equality();
    while (match([TokenType.AND])) {
      var operator = previous();
      var right = equality();
      expr = Logical(expr, operator, right);
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
    return call();
  }

  Expr call() {
    var expr = primary();
    while (true) {
      if (match([TokenType.LEFT_PAREN])) {
        expr = finishCall(expr);
      } else if (match([TokenType.DOT])) {
        var name =
            consume(TokenType.IDENTIFIER, "Expect property name after '.'.");
        expr = Get(expr, name);
      } else {
        break;
      }
    }
    return expr;
  }

  Expr finishCall(Expr callee) {
    var arguments = <Expr>[];
    if (!check(TokenType.RIGHT_PAREN)) {
      var tooMany = false;
      do {
        if (arguments.length >= 255) {
          if (!tooMany) {
            error(peek(), "Can't have more than 255 arguments.");
          }
          tooMany = true;
        }
        arguments.add(expression());
      } while (match([TokenType.COMMA]));
    }
    var paren = consume(TokenType.RIGHT_PAREN, "Expect ')' after arguments.");
    return Call(callee, paren, arguments);
  }

  Expr primary() {
    if (match([TokenType.FALSE])) return Literal(false);
    if (match([TokenType.TRUE])) return Literal(true);
    if (match([TokenType.NIL])) return Literal(null);
    if (match([TokenType.NUMBER, TokenType.STRING])) {
      return Literal(previous().literal);
    }
    if (match([TokenType.SUPER])) {
      var keyword = previous();
      consume(TokenType.DOT, "Expect '.' after 'super'.");
      var method =
          consume(TokenType.IDENTIFIER, 'Expect superclass method name.');
      return Super(keyword, method);
    }
    if (match([TokenType.THIS])) return This(previous());
    if (match([TokenType.IDENTIFIER])) return Variable(previous());
    if (match([TokenType.FUN])) return lambda();
    if (match([TokenType.LEFT_PAREN])) {
      var expr = expression();
      consume(TokenType.RIGHT_PAREN, "Expect ')' after expression.");
      return Grouping(expr);
    }
    throw error(peek(), 'Expect expression.');
  }

  Lambda lambda() {
    consume(TokenType.LEFT_PAREN, "Expect '(' after fun.");
    var parameters = parameterList();
    consume(TokenType.LEFT_BRACE, "Expect '{' before fun body.");
    var body = block();
    return Lambda(parameters, body);
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
