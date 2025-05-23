// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/diagnostics/messages.dart';
import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';

import 'package:compiler/src/util/memory_compiler.dart';

test(String code, List<String> options, List<MessageKind> expectedHints) async {
  DiagnosticCollector collector = DiagnosticCollector();
  CompilationResult result = await runCompiler(
    memorySourceFiles: {'main.dart': code},
    options: options,
    diagnosticHandler: collector,
  );
  Expect.isTrue(result.isSuccess);
  List<MessageKind?> actualHints = collector.hints
      .map((c) => c.messageKind)
      .toList();
  String message =
      "Unexpected hints for $options on\n$code\n"
      "Expected: ${expectedHints}\n"
      "Actual  : ${actualHints}";
  Expect.listEquals(expectedHints, actualHints, message);
}

String runtimeTypeToStringObject = '''
main() {
  print(new Object().runtimeType.toString());
}
''';

String runtimeTypeToStringClass = '''
class Class {}

main() {
  print(new Class().runtimeType.toString());
}
''';

main() {
  asyncTest(() async {
    await test(runtimeTypeToStringObject, [], []);
    await test(
      runtimeTypeToStringObject,
      [Flags.omitImplicitChecks],
      [MessageKind.runtimeTypeToString],
    );
    await test(runtimeTypeToStringObject, [
      Flags.omitImplicitChecks,
      Flags.laxRuntimeTypeToString,
    ], []);

    await test(runtimeTypeToStringClass, [], []);
    await test(
      runtimeTypeToStringClass,
      [Flags.omitImplicitChecks],
      [MessageKind.runtimeTypeToString],
    );
    await test(runtimeTypeToStringClass, [
      Flags.omitImplicitChecks,
      Flags.laxRuntimeTypeToString,
    ], []);
  });
}
