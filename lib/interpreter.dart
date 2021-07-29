import 'package:ilox/builtins.dart';
import 'package:ilox/expr.dart';
import 'package:ilox/environment.dart';
import 'package:ilox/ilox.dart';
import 'package:ilox/lox_callable.dart';
import 'package:ilox/lox_class.dart';
import 'package:ilox/lox_function.dart';
import 'package:ilox/lox_instance.dart';
import 'package:ilox/return.dart';
import 'package:ilox/stmt.dart';
import 'package:ilox/token.dart';
import 'package:ilox/token_type.dart';

class Interpreter implements ExprVisitor<Object>, StmtVisitor<void> {
  final Environment globals;
  Environment environment;
  final locals = <Expr, int>{};
  bool isBreak = false;
  bool isContinue = false;

  Interpreter() : globals = Environment() {
    defineBuiltins(globals);
    environment = globals;
  }

  void resolve(Expr expr, int depth) {
    locals[expr] = depth;
  }

  Object lookUpVariable(Token name, Expr expr) {
    var distance = locals[expr];
    if (distance != null) {
      return environment.getAt(distance, name.lexeme);
    } else {
      return globals.get(name);
    }
  }

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
  }

  @override
  Object visitVariableExpr(Variable expr) {
    return lookUpVariable(expr.name, expr);
  }

  @override
  Object visitAssignExpr(Assign expr) {
    var value = evaluate(expr.value);
    var distance = locals[expr];
    if (distance != null) {
      environment.assignAt(distance, expr.name, value);
    } else {
      globals.assign(expr.name, value);
    }
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
        if (isBreak || isContinue) break;
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
    while (isTruthy(evaluate(stmt.condition)) && !isBreak) {
      execute(stmt.body);
      isContinue = false;
    }
    isBreak = false;
  }

  @override
  void visitBreakStmt(Break stmt) {
    isBreak = true;
  }

  @override
  void visitContinueStmt(Continue stmt) {
    isContinue = true;
  }

  @override
  Object visitCallExpr(Call expr) {
    var callee = evaluate(expr.callee);
    var arguments = <Object>[];
    for (var argument in expr.arguments) {
      arguments.add(evaluate(argument));
    }
    if (callee is! LoxCallable) {
      throw RuntimeError(expr.paren, 'Can only call functions and classes.');
    }
    var function = callee as LoxCallable;
    if (arguments.length != function.arity()) {
      throw RuntimeError(expr.paren,
          'Expected ${function.arity()} arguments but got ${arguments.length}.');
    }
    return function.call(this, arguments);
  }

  @override
  void visitFuncStmt(Func stmt) {
    var function =
        LoxFunction(stmt.name, stmt.params, stmt.body, environment, false);
    environment.define(stmt.name.lexeme, function);
  }

  @override
  void visitReturnStmt(Return stmt) {
    Object value;
    if (stmt.value != null) value = evaluate(stmt.value);
    throw ReturnException(value);
  }

  @override
  Object visitLambdaExpr(Lambda expr) {
    var function =
        LoxFunction(null, expr.params, expr.body, environment, false);
    return function;
  }

  @override
  void visitClassStmt(Class stmt) {
    Object superclass;
    if (stmt.superclass != null) {
      superclass = evaluate(stmt.superclass);
      if (superclass is! LoxClass) {
        throw RuntimeError(stmt.superclass.name, 'Superclass must be a class.');
      }
    }
    environment.define(stmt.name.lexeme, null);
    if (stmt.superclass != null) {
      // Define environment to hold 'super'
      environment = Environment(environment);
      environment.define('super', superclass);
    }
    var methods = <String, LoxFunction>{};
    for (var method in stmt.methods) {
      var function = LoxFunction(method.name, method.params, method.body,
          environment, method.name.lexeme == 'init');
      methods[method.name.lexeme] = function;
    }
    var klass = LoxClass(stmt.name.lexeme, (superclass as LoxClass), methods);
    if (superclass != null) {
      environment = environment.enclosing;
    }
    environment.assign(stmt.name, klass);
  }

  @override
  Object visitGetExpr(Get expr) {
    var object = evaluate(expr.object);
    if (object is LoxInstance) {
      return object.get(expr.name);
    }
    throw RuntimeError(expr.name, 'Only instances have properties.');
  }

  @override
  Object visitSetExpr(Set expr) {
    var object = evaluate(expr.object);
    if (object is! LoxInstance) {
      throw RuntimeError(expr.name, 'Only instances have fields.');
    }
    var value = evaluate(expr.value);
    (object as LoxInstance).set(expr.name, value);
    return value;
  }

  @override
  Object visitThisExpr(This expr) {
    return lookUpVariable(expr.keyword, expr);
  }

  @override
  Object visitSuperExpr(Super expr) {
    var distance = locals[expr];
    // Environment for 'super'
    var superclass = environment.getAt(distance, 'super') as LoxClass;
    // Environment for 'this' is next
    var object = environment.getAt(distance - 1, 'this') as LoxInstance;
    var method = superclass.findMethod(expr.method.lexeme);
    if (method == null) {
      throw RuntimeError(
          expr.method, "Undefined property '${expr.method.lexeme}'.");
    }
    return method.bind(object);
  }
}

class RuntimeError implements Exception {
  final Token token;
  final String message;

  RuntimeError(this.token, [this.message]);

  @override
  String toString() => "${message ?? 'RuntimeError'} ${token ?? 'no token'}";
}
