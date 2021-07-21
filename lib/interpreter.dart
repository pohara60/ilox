import 'package:ilox/expr.dart';
import 'package:ilox/stmt.dart';
import 'package:ilox/token.dart';
import 'package:ilox/token_type.dart';

import 'environment.dart';
import 'ilox.dart';

class Interpreter implements ExprVisitor<Object>, StmtVisitor<void> {
  Environment environment = Environment();

  void interpret(List<Stmt> statements) {
    try {
      for (var statement in statements) {
        execute(statement);
      }
    } on RuntimeError catch (error) {
      Lox.runtimeError(error);
    }
  }

  void execute(Stmt stmt) {
    stmt.accept(this);
  }

  Object evaluate(Expr expr) {
    return expr.accept(this);
  }

  @override
  Object visitBinaryExpr(Binary expr) {
    var left = evaluate(expr.left);
    var right = evaluate(expr.right);
    //ignore: missing_enum_constant_in_switch
    switch (expr.operator.type) {
      case TokenType.MINUS:
        checkNumberOperands(expr.operator, left, right);
        return (left as double) - (right as double);
      case TokenType.SLASH:
        checkNumberOperands(expr.operator, left, right);
        if (right as double == 0.0) {
          throw RuntimeError(expr.operator, 'Divide by zero.');
        }
        return (left as double) / (right as double);
      case TokenType.STAR:
        checkNumberOperands(expr.operator, left, right);
        return (left as double) * (right as double);
      case TokenType.PLUS:
        if (left is double && right is double) {
          return left + right;
        }
        if (left is String && right is String) {
          return left + right;
        }
        return stringify(left) + stringify(right);
        // throw RuntimeError(
        //     expr.operator, 'Operands must be two numbers or two strings.');
        break;
      case TokenType.GREATER:
        checkMatchingOperands(expr.operator, left, right);
        return isGreater(left, right);
      case TokenType.GREATER_EQUAL:
        checkMatchingOperands(expr.operator, left, right);
        return isGreater(left, right) || isEqual(left, right);
      case TokenType.LESS:
        checkMatchingOperands(expr.operator, left, right);
        return !(isGreater(left, right) || isEqual(left, right));
      case TokenType.LESS_EQUAL:
        checkMatchingOperands(expr.operator, left, right);
        return !isGreater(left, right);
      case TokenType.BANG_EQUAL:
        return !isEqual(left, right);
      case TokenType.EQUAL_EQUAL:
        return isEqual(left, right);
    }
    // Unreachable.
    return null;
  }

  @override
  Object visitGroupingExpr(Grouping expr) {
    return evaluate(expr.expression);
  }

  @override
  Object visitLiteralExpr(Literal expr) {
    return expr.value;
  }

  @override
  Object visitUnaryExpr(Unary expr) {
    var right = evaluate(expr.right);
    //ignore: missing_enum_constant_in_switch
    switch (expr.operator.type) {
      case TokenType.MINUS:
        checkNumberOperand(expr.operator, right);
        return -(right as double);
      case TokenType.BANG:
        return !isTruthy(right);
    }
    // Unreachable.
    return null;
  }

  bool isTruthy(Object object) {
    if (object == null) return false;
    if (object is bool) return object;
    return true;
  }

  bool isEqual(Object a, Object b) {
    return a == b;
  }

  bool isGreater(Object a, Object b) {
    if (a is double && b is double) return a > b;
    if (a is String && b is String) return a.compareTo(b) > 0;
    // Unreached
    return false;
  }

  void checkNumberOperand(Token operator, Object operand) {
    if (operand is double) return;
    throw RuntimeError(operator, 'Operand must be a number.');
  }

  void checkNumberOperands(Token operator, Object left, Object right) {
    if (left is double && right is double) return;
    throw RuntimeError(operator, 'Operands must be numbers.');
  }

  void checkMatchingOperands(Token operator, Object left, Object right) {
    if (left is double && right is double) return;
    if (left is String && right is String) return;
    throw RuntimeError(
        operator, 'Operands must be two numbers or two strings.');
  }

  String stringify(Object object) {
    if (object == null) return 'nil';
    if (object is double) {
      var text = object.toString();
      if (text.endsWith('.0')) {
        text = text.substring(0, text.length - 2);
      }
      return text;
    }
    return object.toString();
  }

  @override
  void visitExpressionStmt(Expression stmt) {
    evaluate(stmt.expression);
  }

  @override
  void visitPrintStmt(Print stmt) {
    var value = evaluate(stmt.expression);
    print(stringify(value));
  }

  @override
  void visitVarStmt(Var stmt) {
    Object value;
    if (stmt.initializer != null) {
      value = evaluate(stmt.initializer);
    }
    environment.define(stmt.name.lexeme, value);
    return null;
  }

  @override
  Object visitVariableExpr(Variable expr) {
    return environment.get(expr.name);
  }

  @override
  Object visitAssignExpr(Assign expr) {
    var value = evaluate(expr.value);
    environment.assign(expr.name, value);
    return value;
  }

  @override
  void visitBlockStmt(Block stmt) {
    executeBlock(stmt.statements, Environment(environment));
  }

  void executeBlock(List<Stmt> statements, Environment environment) {
    var previous = this.environment;
    try {
      this.environment = environment;
      for (var statement in statements) {
        execute(statement);
      }
    } finally {
      this.environment = previous;
    }
  }

  @override
  void visitIfStmt(If stmt) {
    if (isTruthy(evaluate(stmt.condition))) {
      execute(stmt.thenBranch);
    } else if (stmt.elseBranch != null) {
      execute(stmt.elseBranch);
    }
  }

  @override
  Object visitLogicalExpr(Logical expr) {
    var left = evaluate(expr.left);
    if (expr.operator.type == TokenType.OR) {
      if (isTruthy(left)) return left;
    } else {
      if (!isTruthy(left)) return left;
    }
    return evaluate(expr.right);
  }

  @override
  void visitWhileStmt(While stmt) {
    while (isTruthy(evaluate(stmt.condition))) {
      execute(stmt.body);
    }
  }
}

class RuntimeError implements Exception {
  final Token token;
  final String message;

  RuntimeError(this.token, [this.message]);

  @override
  String toString() => "${message ?? 'RuntimeError'} ${token ?? 'no token'}";
}
