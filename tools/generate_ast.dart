import 'dart:io';

void main(List<String> args) {
  if (args.length != 1) {
    stderr.write('Usage: generate_ast <output directory>');
    exit(64);
  }
  var outputDir = args[0];

  defineAst(outputDir, 'Expr', [
    'Assign   : Token name, Expr value',
    'Binary   : Expr left, Token operator, Expr right',
    'Logical  : Expr left, Token operator, Expr right',
    'Grouping : Expr expression',
    'Literal  : Object value',
    'Unary    : Token operator, Expr right',
    'Call     : Expr callee, Token paren, List<Expr> arguments',
    'Get      : Expr object, Token name',
    'Set      : Expr object, Token name, Expr value',
    'Super    : Token keyword, Token method',
    'This     : Token keyword',
    'Variable : Token name',
    'Lambda   : List<Token> params, List<Stmt> body',
  ]);

  defineAst(outputDir, 'Stmt', [
    'Block      : List<Stmt> statements',
    'If         : Expr condition, Stmt thenBranch, Stmt elseBranch',
    'While      : Expr condition, Stmt body',
    'Break      : ',
    'Continue   : ',
    'Expression : Expr expression',
    'Print      : Expr expression',
    'Var        : Token name, Expr initializer',
    'Func       : Token name, List<Token> params, List<Stmt> body',
    'Return     : Token keyword, Expr value',
    'Class      : Token name, Variable superclass, List<Func> methods, List<Func> functions',
  ]);
}

void defineAst(String outputDir, String baseName, List<String> types) {
  var path = '$outputDir/${baseName.toLowerCase()}.dart';
  var file = File(path);
  var output = StringBuffer();

  if (baseName == 'Stmt') {
    output.writeln("import 'package:ilox/expr.dart';");
  }
  if (baseName == 'Expr') {
    output.writeln("import 'package:ilox/stmt.dart';");
  }
  output.writeln("import 'package:ilox/token.dart';");
  output.writeln();
  output.writeln('abstract class $baseName {');
  output.writeln('  T accept<T>(${baseName}Visitor<T> visitor);');
  output.writeln('}');
  output.writeln();
  defineVisitor(output, baseName, types);
  for (var type in types) {
    var className = type.split(':')[0].trim();
    var fields = type.split(':')[1].trim();
    defineType(output, baseName, className, fields);
  }
  file.writeAsStringSync(output.toString());
}

void defineType(
    StringBuffer output, String baseName, String className, String fieldList) {
  output.writeln();
  output.writeln('class $className extends $baseName {');

  // Constructor.
  output.writeln('  $className (');
  //print('class=$className');

  // Store parameters in fields.
  var fields = fieldList.split(', ');
  for (var field in fields) {
    if (field.isNotEmpty) {
      var name = field.split(' ')[1];
      output.writeln('    this.$name,');
    }
  }

  output.writeln('  );');

  // Fields.
  for (var field in fields) {
    if (field.isNotEmpty) {
      output.writeln('  final ' + field + ';');
    }
  }

  output.writeln('');
  output.writeln('  @override');
  output.writeln('  T accept<T>(${baseName}Visitor<T> visitor) {');
  output.writeln('    return visitor.visit$className$baseName(this);');
  output.writeln('  }');

  output.writeln('}');
}

void defineVisitor(StringBuffer output, String baseName, List<String> types) {
  output.writeln('abstract class ${baseName}Visitor<T> {');

  for (var type in types) {
    var typeName = type.split(':')[0].trim();
    output.writeln(
        '  T visit$typeName$baseName($typeName ${baseName.toLowerCase()});');
  }

  output.writeln('}');
}
