import 'package:ilox/expr.dart';
import 'package:ilox/stmt.dart';
import 'package:ilox/token.dart';

class AstPrinter implements ExprVisitor<String>, StmtVisitor<String> {
  String print(Expr expr) {
    return expr.accept(this);
  }

  @override
  String visitBinaryExpr(Binary expr) {
    return parenthesize(expr.operator.lexeme, expr.left, expr.right);
  }

  @override
  String visitGroupingExpr(Grouping expr) {
    return parenthesize('group', expr.expression);
  }

  @override
  String visitLiteralExpr(Literal expr) {
    if (expr.value == null) return 'nil';
    return expr.value.toString();
  }

  @override
  String visitUnaryExpr(Unary expr) {
    return parenthesize(expr.operator.lexeme, expr.right);
  }

  String parenthesize(String name, [Expr expr, Expr expr2]) {
    var buffer = StringBuffer();

    buffer.write('(');
    buffer.write(name);
    if (expr2 != null) {
      buffer.write(' ');
      buffer.write(expr.accept(this));
    }
    if (expr2 != null) {
      buffer.write(' ');
      buffer.write(expr2.accept(this));
    }
    buffer.write(')');

    return buffer.toString();
  }

  String parenthesizeVar(String name, Token token, [Expr expr]) {
    var buffer = StringBuffer();

    buffer.write('(');
    buffer.write(name);
    buffer.write(' ');
    buffer.write(token.lexeme);
    if (expr != null) {
      buffer.write(' ');
      buffer.write(expr.accept(this));
    }
    buffer.write(')');

    return buffer.toString();
  }

  String parenthesizeGet(String name, Expr object, Token token, [Expr value]) {
    var buffer = StringBuffer();

    buffer.write('(');
    buffer.write(name);
    buffer.write(' ');
    buffer.write(object.accept(this));
    buffer.write('.');
    buffer.write(token.lexeme);
    if (value != null) {
      buffer.write(' ');
      buffer.write(value.accept(this));
    }
    buffer.write(')');

    return buffer.toString();
  }

  String parenthesizeFun(
      String name, Token token, List<Token> params, List<Stmt> body) {
    var buffer = StringBuffer();

    buffer.write('(');
    buffer.write(name);
    buffer.write(' ');
    buffer.write(token.lexeme);
    buffer.write(' ( ');
    for (var param in params) {
      buffer.write(' ');
      buffer.write(param.lexeme);
    }
    buffer.write(' ) ');
    parenthesizeStmts('body', body);
    buffer.write(')');

    return buffer.toString();
  }

  String parenthesizeClass(String name, Token token, List<Func> methods) {
    var buffer = StringBuffer();

    buffer.write('(');
    buffer.write(name);
    buffer.write(' ');
    buffer.write(token.lexeme);
    buffer.write(' (');
    for (var method in methods) {
      buffer.write(' ');
      parenthesizeFun('method', method.name, method.params, method.body);
    }
    buffer.write(' ) ');

    return buffer.toString();
  }

  String parenthesizeStmts(String name, List<Stmt> statements) {
    var buffer = StringBuffer();

    buffer.write('(');
    buffer.write(name);
    for (var statement in statements) {
      buffer.write(' ');
      buffer.write(statement.accept(this));
    }
    buffer.write(')');

    return buffer.toString();
  }

  String parenthesizeIfStmt(String name, Expr condition, Stmt thenStatement,
      [Stmt elseStatement]) {
    var buffer = StringBuffer();

    buffer.write('(');
    buffer.write(name);
    buffer.write(' ');
    buffer.write(condition.accept(this));
    buffer.write(' ');
    buffer.write(thenStatement.accept(this));
    if (elseStatement != null) {
      buffer.write(' ');
      buffer.write(elseStatement.accept(this));
    }
    buffer.write(')');

    return buffer.toString();
  }

  String parenthesizeCall(String name, Expr callee, List<Expr> arguments) {
    var buffer = StringBuffer();

    buffer.write('(');
    buffer.write(name);
    buffer.write(' ');
    buffer.write(callee.accept(this));
    buffer.write(' ( ');
    for (var argument in arguments) {
      buffer.write(' ');
      buffer.write(argument.accept(this));
    }
    buffer.write(' ) ');
    buffer.write(')');

    return buffer.toString();
  }

  @override
  String visitExpressionStmt(Expression stmt) {
    return parenthesize('expression', stmt.expression);
  }

  @override
  String visitPrintStmt(Print stmt) {
    return parenthesize('print', stmt.expression);
  }

  @override
  String visitVarStmt(Var stmt) {
    return parenthesizeVar('var', stmt.name, stmt.initializer);
  }

  @override
  String visitVariableExpr(Variable expr) {
    return parenthesizeVar('var', expr.name);
  }

  @override
  String visitAssignExpr(Assign expr) {
    return parenthesizeVar('assign', expr.name, expr.value);
  }

  @override
  String visitBlockStmt(Block stmt) {
    return parenthesizeStmts('block', stmt.statements);
  }

  @override
  String visitIfStmt(If stmt) {
    return parenthesizeIfStmt(
        'if', stmt.condition, stmt.thenBranch, stmt.elseBranch);
  }

  @override
  String visitLogicalExpr(Logical expr) {
    return parenthesize(expr.operator.lexeme, expr.left, expr.right);
  }

  @override
  String visitWhileStmt(While stmt) {
    return parenthesizeIfStmt('while', stmt.condition, stmt.body);
  }

  @override
  String visitBreakStmt(Break stmt) {
    return parenthesize('break');
  }

  @override
  String visitContinueStmt(Continue stmt) {
    return parenthesize('continue');
  }

  @override
  String visitCallExpr(Call expr) {
    return parenthesizeCall('call', expr.callee, expr.arguments);
  }

  @override
  String visitFuncStmt(Func stmt) {
    return parenthesizeFun('fun', stmt.name, stmt.params, stmt.body);
  }

  @override
  String visitReturnStmt(Return stmt) {
    return parenthesize(stmt.keyword.lexeme, stmt.value);
  }

  @override
  String visitLambdaExpr(Lambda expr) {
    return parenthesizeFun('lambda', null, expr.params, expr.body);
  }

  @override
  String visitClassStmt(Class stmt) {
    return parenthesizeClass('class', stmt.name, stmt.methods);
  }

  @override
  String visitGetExpr(Get expr) {
    return parenthesizeGet('get', expr.object, expr.name);
  }

  @override
  String visitSetExpr(Set expr) {
    return parenthesizeGet('set', expr.object, expr.name, expr.value);
  }

  @override
  String visitThisExpr(This expr) {
    return parenthesizeVar('var', expr.keyword);
  }
}
