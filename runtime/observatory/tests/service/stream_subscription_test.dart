// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'package:observatory/service_io.dart';
import 'test_helper.dart';

Future streamListen(VM vm, String streamId) async =>
    await vm.invokeRpcNoUpgrade(
      'streamListen',
      {
        'streamId': streamId,
      },
    );

Future streamCancel(VM vm, String streamId) async =>
    await vm.invokeRpcNoUpgrade(
      'streamCancel',
      {
        'streamId': streamId,
      },
    );

var tests = <VMTest>[
  // Check double subscription fails.
  (VM vm) async {
    await streamListen(vm, '_Echo');
    try {
      await streamListen(vm, '_Echo');
      fail('Subscribed to stream twice');
    } on ServerRpcException catch (e) {
      expect(e.message, 'Stream already subscribed');
    }
  },
  // Check double cancellation fails.
  (VM vm) async {
    await streamCancel(vm, '_Echo');
    try {
      await streamCancel(vm, '_Echo');
      fail('Double cancellation of stream successful');
    } on ServerRpcException catch (e) {
      expect(e.message, 'Stream not subscribed');
    }
  },
];

main(args) => runVMTests(args, tests);
