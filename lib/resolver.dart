import 'package:ilox/expr.dart';
import 'package:ilox/ilox.dart';
import 'package:ilox/interpreter.dart';
import 'package:ilox/stmt.dart';
import 'package:ilox/token.dart';

enum FunctionType { NONE, FUNCTION }

class Resolver implements ExprVisitor<void>, StmtVisitor<void> {
  final Interpreter interpreter;
  final List<Map<String, bool>> scopes = <Map<String, bool>>[];
  FunctionType currentFunction = FunctionType.NONE;

  Resolver(this.interpreter);

  void resolve(List<Stmt> statements) {
    for (var statement in statements) {
      resolveStmt(statement);
    }
  }

  void resolveStmt(Stmt stmt) {
    stmt.accept(this);
  }

  void resolveExpr(Expr expr) {
    expr.accept(this);
  }

  void resolveLocal(Expr expr, Token name) {
    for (var i = scopes.length - 1; i >= 0; i--) {
      if (scopes[i].containsKey(name.lexeme)) {
        interpreter.resolve(expr, scopes.length - 1 - i);
        return;
      }
    }
  }

  void resolveFunction(List<Token> params, List<Stmt> body, FunctionType type) {
    var enclosingFunction = currentFunction;
    currentFunction = type;
    beginScope();
    for (var param in params) {
      declare(param);
      define(param);
    }
    resolve(body);
    endScope();
    currentFunction = enclosingFunction;
  }

  void beginScope() {
    scopes.add(<String, bool>{});
  }

  void endScope() {
    scopes.removeLast();
  }

  // Variable declared
  void declare(Token name) {
    if (scopes.isEmpty) return;
    var scope = scopes[scopes.length - 1];
    if (scope.containsKey(name.lexeme)) {
      Lox.errorToken(name, 'Already a variable with this name in this scope.');
    }
    scope[name.lexeme] = false;
  }

  // Variable defined, i.e. after initializer evaluated
  void define(Token name) {
    if (scopes.isEmpty) return;
    scopes[scopes.length - 1][name.lexeme] = true;
  }

  @override
  void visitAssignExpr(Assign expr) {
    resolveExpr(expr.value);
    resolveLocal(expr, expr.name);
    return null;
  }

  @override
  void visitBinaryExpr(Binary expr) {
    resolveExpr(expr.left);
    resolveExpr(expr.right);
    return null;
  }

  @override
  void visitBlockStmt(Block stmt) {
    beginScope();
    resolve(stmt.statements);
    endScope();
    return null;
  }

  @override
  void visitBreakStmt(Break stmt) {
    return null;
  }

  @override
  void visitCallExpr(Call expr) {
    resolveExpr(expr.callee);
    for (var argument in expr.arguments) {
      resolveExpr(argument);
    }
    return null;
  }

  @override
  void visitContinueStmt(Continue stmt) {
    return null;
  }

  @override
  void visitExpressionStmt(Expression stmt) {
    resolveExpr(stmt.expression);
    return null;
  }

  @override
  void visitFuncStmt(Func stmt) {
    declare(stmt.name);
    define(stmt.name);
    resolveFunction(stmt.params, stmt.body, FunctionType.FUNCTION);
    return null;
  }

  @override
  void visitGroupingExpr(Grouping expr) {
    resolveExpr(expr.expression);
    return null;
  }

  @override
  void visitIfStmt(If stmt) {
    resolveExpr(stmt.condition);
    resolveStmt(stmt.thenBranch);
    if (stmt.elseBranch != null) resolveStmt(stmt.elseBranch);
    return null;
  }

  @override
  void visitLambdaExpr(Lambda expr) {
    resolveFunction(expr.params, expr.body, FunctionType.FUNCTION);
    return null;
  }

  @override
  void visitLiteralExpr(Literal expr) {
    return null;
  }

  @override
  void visitLogicalExpr(Logical expr) {
    resolveExpr(expr.left);
    resolveExpr(expr.right);
    return null;
  }

  @override
  void visitPrintStmt(Print stmt) {
    resolveExpr(stmt.expression);
    return null;
  }

  @override
  void visitReturnStmt(Return stmt) {
    if (currentFunction == FunctionType.NONE) {
      Lox.errorToken(stmt.keyword, "Can't return from top-level code.");
    }
    if (stmt.value != null) {
      resolveExpr(stmt.value);
    }
    return null;
  }

  @override
  void visitUnaryExpr(Unary expr) {
    resolveExpr(expr.right);
    return null;
  }

  @override
  void visitVarStmt(Var stmt) {
    declare(stmt.name);
    if (stmt.initializer != null) {
      resolveExpr(stmt.initializer);
    }
    define(stmt.name);
    return null;
  }

  @override
  void visitVariableExpr(Variable expr) {
    if (scopes.isNotEmpty &&
        scopes[scopes.length - 1][expr.name.lexeme] == false) {
      Lox.errorToken(
          expr.name, "Can't read local variable in its own initializer.");
    }

    resolveLocal(expr, expr.name);
    return null;
  }

  @override
  void visitWhileStmt(While stmt) {
    resolveExpr(stmt.condition);
    resolveStmt(stmt.body);
    return null;
  }
}
