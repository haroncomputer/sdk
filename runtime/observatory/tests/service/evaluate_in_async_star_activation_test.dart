// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

import 'package:test/test.dart';

import 'package:observatory/service_io.dart';
import 'service_test_common.dart';
import 'test_helper.dart';

generator() async* {
  var x = 3;
  var y = 4;
  debugger();
  yield y;
  var z = x + y;
  debugger();
  yield z;
}

testFunction() async {
  await for (var _ in generator());
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  (Isolate isolate) async {
    // Make sure we are in the right place.
    var stack = await isolate.getStack();
    var topFrame = 0;
    expect(stack.type, equals('Stack'));
    expect(await stack['frames'][topFrame].location.getLine(), 16);

    Instance result = await isolate.evalFrame(topFrame, "x") as Instance;
    print(result);
    expect(result.valueAsString, equals("3"));
  },
  resumeIsolate,
  hasStoppedAtBreakpoint,
  (Isolate isolate) async {
    // Make sure we are in the right place.
    var stack = await isolate.getStack();
    var topFrame = 0;
    expect(stack.type, equals('Stack'));
    expect(await stack['frames'][topFrame].location.getLine(), 19);

    Instance result = await isolate.evalFrame(topFrame, "z") as Instance;
    print(result);
    expect(result.valueAsString, equals("7"));
  },
  resumeIsolate,
];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testFunction);
