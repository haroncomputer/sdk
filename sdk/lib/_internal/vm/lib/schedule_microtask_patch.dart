// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "async_patch.dart";

@patch
abstract final class _MicrotaskMirrorQueue {
  @patch
  @pragma("vm:external-name", "MicrotaskMirrorQueue_onScheduleAsyncCallback")
  external static void _onScheduleAsyncCallback();

  @patch
  @pragma(
    "vm:external-name",
    "MicrotaskMirrorQueue_onSchedulePriorityAsyncCallback",
  )
  external static void _onSchedulePriorityAsyncCallback();

  @patch
  @pragma("vm:external-name", "MicrotaskMirrorQueue_onAsyncCallbackComplete")
  external static void _onAsyncCallbackComplete(int startTime, int endTime);
}

@patch
class _AsyncRun {
  @patch
  static void _scheduleImmediate(void callback()) {
    final closure = _ScheduleImmediate._closure;
    if (closure == null) {
      throw UnsupportedError("Microtasks are not supported");
    }
    closure(callback);
  }
}

typedef void _ScheduleImmediateClosure(void callback());

class _ScheduleImmediate {
  static _ScheduleImmediateClosure? _closure;
}

@pragma("vm:entry-point", "call")
void _setScheduleImmediateClosure(_ScheduleImmediateClosure closure) {
  _ScheduleImmediate._closure = closure;
}

@pragma("vm:entry-point", "call")
void _ensureScheduleImmediate() {
  _AsyncRun._scheduleImmediate(_startMicrotaskLoop);
}
