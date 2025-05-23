// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:compiler/src/commandline_options.dart';
import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:compiler/src/util/memory_compiler.dart';

main() {
  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await test([]);
  });
}

test(List<String> options) async {
  DiagnosticCollector collector = DiagnosticCollector();
  String fileName = 'sdk/tests/web/native/main.dart';
  Uri entryPoint = Uri.parse('memory:$fileName');
  await runCompiler(
    entryPoint: entryPoint,
    memorySourceFiles: {
      fileName: '''
        import 'dart:html';
        import 'dart:_js_helper';

        method(o) native;

        main() {
          method(document);
        }
        ''',
    },
    diagnosticHandler: collector,
    options: [Flags.verbose]..addAll(options),
  );
  int allNativeUsedCount = collector.verboseInfos.where((
    CollectedMessage message,
  ) {
    return message.text.startsWith('All native types marked as used due to ');
  }).length;
  Expect.equals(
    1,
    allNativeUsedCount,
    "Unexpected message count: $allNativeUsedCount",
  );
}
