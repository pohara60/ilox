import 'package:ilox/expr.dart';
import 'package:ilox/ilox.dart';
import 'package:ilox/interpreter.dart';
import 'package:ilox/stmt.dart';
import 'package:ilox/token.dart';

enum FunctionType { NONE, FUNCTION, METHOD, INITIALIZER }
enum ClassType { NONE, CLASS, SUBCLASS }

enum LocalState { DEFINED, DECLARED, USED }

class Local {
  final Token name;
  LocalState state;
  Local(this.name, this.state);
}

class Resolver implements ExprVisitor<void>, StmtVisitor<void> {
  final Interpreter interpreter;
  final scopes = <Map<String, Local>>[];
  FunctionType currentFunction = FunctionType.NONE;
  ClassType currentClass = ClassType.NONE;

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

  Map<String, Local> resolveLocal(Expr expr, Token name) {
    for (var i = scopes.length - 1; i >= 0; i--) {
      if (scopes[i].containsKey(name.lexeme)) {
        interpreter.resolve(expr, scopes.length - 1 - i);
        return scopes[i];
      }
    }
    return null;
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
    scopes.add(<String, Local>{});
  }

  void endScope() {
    var scope = scopes.last;
    for (var key in scope.keys) {
      if (scope[key].state == LocalState.DEFINED) {
        Lox.errorToken(scope[key].name, 'Variable not used.');
      }
    }
    scopes.removeLast();
  }

  // Variable declared
  void declare(Token name) {
    if (scopes.isEmpty) return;
    var scope = scopes.last;
    if (scope.containsKey(name.lexeme)) {
      Lox.errorToken(name, 'Already a variable with this name in this scope.');
    }
    scope[name.lexeme] = Local(name, LocalState.DECLARED);
  }

  // Variable defined, i.e. after initializer evaluated
  void define(Token name) {
    if (scopes.isEmpty) return;
    scopes.last[name.lexeme].state = LocalState.DEFINED;
  }

  @override
  void visitAssignExpr(Assign expr) {
    resolveExpr(expr.value);
    var scope = resolveLocal(expr, expr.name);
    if (scope != null) {
      scope[expr.name.lexeme].state = LocalState.USED;
    }
  }

  @override
  void visitBinaryExpr(Binary expr) {
    resolveExpr(expr.left);
    resolveExpr(expr.right);
  }

  @override
  void visitBlockStmt(Block stmt) {
    beginScope();
    resolve(stmt.statements);
    endScope();
  }

  @override
  void visitBreakStmt(Break stmt) {}

  @override
  void visitCallExpr(Call expr) {
    resolveExpr(expr.callee);
    for (var argument in expr.arguments) {
      resolveExpr(argument);
    }
  }

  @override
  void visitContinueStmt(Continue stmt) {}

  @override
  void visitExpressionStmt(Expression stmt) {
    resolveExpr(stmt.expression);
  }

  @override
  void visitFuncStmt(Func stmt) {
    declare(stmt.name);
    define(stmt.name);
    resolveFunction(stmt.params, stmt.body, FunctionType.FUNCTION);
  }

  @override
  void visitGroupingExpr(Grouping expr) {
    resolveExpr(expr.expression);
  }

  @override
  void visitIfStmt(If stmt) {
    resolveExpr(stmt.condition);
    resolveStmt(stmt.thenBranch);
    if (stmt.elseBranch != null) resolveStmt(stmt.elseBranch);
  }

  @override
  void visitLambdaExpr(Lambda expr) {
    resolveFunction(expr.params, expr.body, FunctionType.FUNCTION);
  }

  @override
  void visitLiteralExpr(Literal expr) {}

  @override
  void visitLogicalExpr(Logical expr) {
    resolveExpr(expr.left);
    resolveExpr(expr.right);
  }

  @override
  void visitPrintStmt(Print stmt) {
    resolveExpr(stmt.expression);
  }

  @override
  void visitReturnStmt(Return stmt) {
    if (currentFunction == FunctionType.NONE) {
      Lox.errorToken(stmt.keyword, "Can't return from top-level code.");
    }
    if (stmt.value != null) {
      if (currentFunction == FunctionType.INITIALIZER) {
        Lox.errorToken(
            stmt.keyword, "Can't return a value from an initializer.");
      }
      resolveExpr(stmt.value);
    }
  }

  @override
  void visitUnaryExpr(Unary expr) {
    resolveExpr(expr.right);
  }

  @override
  void visitVarStmt(Var stmt) {
    declare(stmt.name);
    if (stmt.initializer != null) {
      resolveExpr(stmt.initializer);
    }
    define(stmt.name);
  }

  @override
  void visitVariableExpr(Variable expr) {
    if (scopes.isNotEmpty) {
      var scope = scopes.last;
      if (scope.containsKey(expr.name.lexeme)) {
        if (scope[expr.name.lexeme].state == LocalState.DECLARED) {
          Lox.errorToken(
              expr.name, "Can't read local variable in its own initializer.");
        }
      }
    }

    var scope = resolveLocal(expr, expr.name);
    if (scope != null) {
      scope[expr.name.lexeme].state = LocalState.USED;
    }
  }

  @override
  void visitWhileStmt(While stmt) {
    resolveExpr(stmt.condition);
    resolveStmt(stmt.body);
  }

  @override
  void visitClassStmt(Class stmt) {
    var enclosingClass = currentClass;
    currentClass = ClassType.CLASS;
    declare(stmt.name);
    define(stmt.name);
    if (stmt.superclass != null &&
        stmt.name.lexeme == stmt.superclass.name.lexeme) {
      Lox.errorToken(
          stmt.superclass.name, "A class can't inherit from itself.");
    }
    if (stmt.superclass != null) {
      currentClass = ClassType.SUBCLASS;
      resolveExpr(stmt.superclass);
    }
    if (stmt.superclass != null) {
      // Create scope to define 'super'
      beginScope();
      scopes.last['super'] = Local(stmt.name, LocalState.USED);
    }
    // Create scope to define 'this' for closure
    beginScope();
    scopes.last['this'] = Local(stmt.name, LocalState.USED);
    for (var method in stmt.methods) {
      var declaration = FunctionType.METHOD;
      if (method.name.lexeme == 'init') {
        declaration = FunctionType.INITIALIZER;
      }
      resolveFunction(method.params, method.body, declaration);
    }
    endScope();
    if (stmt.superclass != null) endScope();
    currentClass = enclosingClass;
  }

  @override
  void visitGetExpr(Get expr) {
    resolveExpr(expr.object);
    // Properties are resolved dynamically by the interpreter
  }

  @override
  void visitSetExpr(Set expr) {
    resolveExpr(expr.value);
    resolveExpr(expr.object);
    // Properties are resolved dynamically by the interpreter
  }

  @override
  void visitThisExpr(This expr) {
    if (currentClass == ClassType.NONE) {
      Lox.errorToken(expr.keyword, "Can't use 'this' outside of a class.");
      return;
    }
    resolveLocal(expr, expr.keyword);
  }

  @override
  void visitSuperExpr(Super expr) {
    if (currentClass == ClassType.NONE) {
      Lox.errorToken(expr.keyword, "Can't use 'super' outside of a class.");
    } else if (currentClass != ClassType.SUBCLASS) {
      Lox.errorToken(
          expr.keyword, "Can't use 'super' in a class with no superclass.");
    }
    resolveLocal(expr, expr.keyword);
  }
}
