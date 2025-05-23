// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:test/test.dart';

import 'package:observatory/service_io.dart';
import 'test_helper.dart';

// AUTOGENERATED START
//
// Update these constants by running:
//
// dart pkg/vm_service/test/update_line_numbers.dart runtime/observatory/tests/service/debugging_test.dart
//
const LINE_A = 25;
// AUTOGENERATED END

int counter = 0;

void periodicTask(_) {
  counter++;
  counter++; // LINE_A
  counter++;
  if (counter % 300 == 0) {
    print('counter = $counter');
  }
}

void startTimer() {
  new Timer.periodic(const Duration(milliseconds: 10), periodicTask);
}

var tests = <IsolateTest>[
// Pause
  (Isolate isolate) async {
    Completer completer = new Completer();
    var stream = await isolate.vm.getEventStream(VM.kDebugStream);
    var subscription;
    subscription = stream.listen((ServiceEvent event) {
      if (event.kind == ServiceEvent.kPauseInterrupted) {
        subscription.cancel();
        completer.complete();
      }
    });
    isolate.pause();
    await completer.future;
  },

// Resume
  (Isolate isolate) async {
    Completer completer = new Completer();
    var stream = await isolate.vm.getEventStream(VM.kDebugStream);
    var subscription;
    subscription = stream.listen((ServiceEvent event) {
      if (event.kind == ServiceEvent.kResume) {
        subscription.cancel();
        completer.complete();
      }
    });
    isolate.resume();
    await completer.future;
  },

// Add breakpoint
  (Isolate isolate) async {
    await isolate.rootLibrary.load() as Library;

    // Set up a listener to wait for breakpoint events.
    Completer completer = new Completer();
    var stream = await isolate.vm.getEventStream(VM.kDebugStream);
    var subscription;
    subscription = stream.listen((ServiceEvent event) {
      if (event.kind == ServiceEvent.kPauseBreakpoint) {
        print('Breakpoint reached');
        subscription.cancel();
        completer.complete();
      }
    });

    var script = isolate.rootLibrary.scripts[0];
    await script.load();

    // Add the breakpoint.
    Breakpoint bpt = await isolate.addBreakpoint(script, LINE_A);
    expect(bpt.type, equals('Breakpoint'));
    expect(bpt.location!.script!.id, equals(script.id));
    expect(
        bpt.location!.script!.tokenToLine(bpt.location!.tokenPos), equals(LINE_A));
    expect(isolate.breakpoints.length, equals(1));

    await completer.future; // Wait for breakpoint events.
  },

// We are at the breakpoint on line LINE_A.
  (Isolate isolate) async {
    ServiceMap stack = await isolate.getStack();
    expect(stack.type, equals('Stack'));
    expect(stack['frames'].length, greaterThanOrEqualTo(1));

    Script script = stack['frames'][0].location.script;
    expect(script.name, endsWith('debugging_test.dart'));
    expect(
        script.tokenToLine(stack['frames'][0].location.tokenPos), equals(LINE_A));
  },

// Stepping
  (Isolate isolate) async {
    // Set up a listener to wait for breakpoint events.
    Completer completer = new Completer();
    var stream = await isolate.vm.getEventStream(VM.kDebugStream);
    var subscription;
    subscription = stream.listen((ServiceEvent event) {
      if (event.kind == ServiceEvent.kPauseBreakpoint) {
        print('Breakpoint reached');
        subscription.cancel();
        completer.complete();
      }
    });

    await isolate.stepOver();
    await completer.future; // Wait for breakpoint events.
  },

// We are now at line LINE_A + 1.
  (Isolate isolate) async {
    ServiceMap stack = await isolate.getStack();
    expect(stack.type, equals('Stack'));
    expect(stack['frames'].length, greaterThanOrEqualTo(1));

    Script script = stack['frames'][0].location.script;
    expect(script.name, endsWith('debugging_test.dart'));
    expect(
        script.tokenToLine(stack['frames'][0].location.tokenPos), equals(LINE_A + 1));
  },

// Remove breakpoint
  (Isolate isolate) async {
    // Set up a listener to wait for breakpoint events.
    Completer completer = new Completer();
    var stream = await isolate.vm.getEventStream(VM.kDebugStream);
    var subscription;
    subscription = stream.listen((ServiceEvent event) {
      if (event.kind == ServiceEvent.kBreakpointRemoved) {
        print('Breakpoint removed');
        expect(isolate.breakpoints.length, equals(0));
        subscription.cancel();
        completer.complete();
      }
    });

    expect(isolate.breakpoints.length, equals(1));
    var bpt = isolate.breakpoints.values.first;
    await isolate.removeBreakpoint(bpt);
    await completer.future;
  },

// Resume
  (Isolate isolate) async {
    Completer completer = new Completer();
    var stream = await isolate.vm.getEventStream(VM.kDebugStream);
    var subscription;
    subscription = stream.listen((ServiceEvent event) {
      if (event.kind == ServiceEvent.kResume) {
        subscription.cancel();
        completer.complete();
      }
    });
    isolate.resume();
    await completer.future;
  },

// Add breakpoint at function entry
  (Isolate isolate) async {
    // Set up a listener to wait for breakpoint events.
    Completer completer = new Completer();
    var stream = await isolate.vm.getEventStream(VM.kDebugStream);
    var subscription;
    subscription = stream.listen((ServiceEvent event) {
      if (event.kind == ServiceEvent.kPauseBreakpoint) {
        print('Breakpoint reached');
        subscription.cancel();
        completer.complete();
      }
    });

    // Find a specific function.
    ServiceFunction function = isolate.rootLibrary.functions
        .firstWhere((f) => f.name == 'periodicTask');
    expect(function, isNotNull);

    // Add the breakpoint at function entry
    var result = await isolate.addBreakpointAtEntry(function);
    Breakpoint bpt = result;
    expect(bpt.type, equals('Breakpoint'));
    expect(bpt.location!.script!.name, equals('debugging_test.dart'));
    expect(
        bpt.location!.script!.tokenToLine(bpt.location!.tokenPos), equals(LINE_A - 2));
    expect(isolate.breakpoints.length, equals(1));

    await completer.future; // Wait for breakpoint events.
  },

// We are now at LINE_A - 2.
  (Isolate isolate) async {
    ServiceMap stack = await isolate.getStack();
    expect(stack.type, equals('Stack'));
    expect(stack['frames'].length, greaterThanOrEqualTo(1));

    Script script = stack['frames'][0].location.script;
    expect(script.name, endsWith('debugging_test.dart'));
    expect(
        script.tokenToLine(stack['frames'][0].location.tokenPos), equals(LINE_A - 2));
  },
];

main(args) => runIsolateTests(args, tests, testeeBefore: startTimer);
