import 'dart:io';

void main(List<String> args) {
  if (args.length != 1) {
    stderr.write('Usage: generate_ast <output directory>');
    exit(64);
  }
  var outputDir = args[0];

  defineAst(outputDir, 'Expr', [
    'Binary   : Expr left, Token operator, Expr right',
    'Grouping : Expr expression',
    'Literal  : Object value',
    'Unary    : Token operator, Expr right'
  ]);
}

void defineAst(String outputDir, String baseName, List<String> types) {
  var path = '$outputDir/${baseName.toLowerCase()}.dart';
  var file = File(path);
  var output = StringBuffer();

  output.writeln("import 'package:ilox/token.dart';");
  output.writeln();
  output.writeln('abstract class $baseName {');
  output.writeln('  T accept<T>(Visitor<T> visitor);');
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

  // Store parameters in fields.
  var fields = fieldList.split(', ');
  for (var field in fields) {
    var name = field.split(' ')[1];
    output.writeln('    this.$name,');
  }

  output.writeln('  );');

  // Fields.
  for (var field in fields) {
    output.writeln('  final ' + field + ';');
  }

  output.writeln('');
  output.writeln('  @override');
  output.writeln('  T accept<T>(Visitor<T> visitor) {');
  output.writeln('    return visitor.visit$className$baseName(this);');
  output.writeln('  }');

  output.writeln('}');
}

void defineVisitor(StringBuffer output, String baseName, List<String> types) {
  output.writeln('abstract class Visitor<T> {');

  for (var type in types) {
    var typeName = type.split(':')[0].trim();
    output.writeln(
        '  T visit$typeName$baseName($typeName ${baseName.toLowerCase()});');
  }

  output.writeln('}');
}