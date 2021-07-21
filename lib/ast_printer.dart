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

  String parenthesize(String name, Expr expr, [Expr expr2]) {
    var buffer = StringBuffer();

    buffer.write('(');
    buffer.write(name);
    buffer.write(' ');
    buffer.write(expr.accept(this));
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
}
