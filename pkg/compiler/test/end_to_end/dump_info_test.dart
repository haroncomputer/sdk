// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that dump-info has no effect on the compiler output.

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:expect/expect.dart';

import 'launch_helper.dart' show dart2JsCommand;

copyDirectory(Directory sourceDir, Directory destinationDir) {
  for (var element in sourceDir.listSync()) {
    if (element.path.endsWith('.git')) continue;
    String newPath = path.join(
      destinationDir.path,
      path.basename(element.path),
    );
    if (element is File) {
      element.copySync(newPath);
    } else if (element is Directory) {
      Directory newDestinationDir = Directory(newPath);
      newDestinationDir.createSync();
      copyDirectory(element, newDestinationDir);
    }
  }
}

void main() {
  Directory tmpDir = Directory.systemTemp.createTempSync('dump_info_test_');
  Directory out1 = Directory.fromUri(tmpDir.uri.resolve('without'));
  out1.createSync();
  Directory out2 = Directory.fromUri(tmpDir.uri.resolve('json'));
  out2.createSync();
  Directory out3 = Directory.fromUri(tmpDir.uri.resolve('binary'));
  out3.createSync();
  Directory appDir = Directory.fromUri(
    Uri.base.resolve('pkg/compiler/test/codesize/swarm'),
  );

  print("Copying '${appDir.path}' to '${tmpDir.path}'.");
  copyDirectory(appDir, tmpDir);
  try {
    var command = dart2JsCommand(['--out=without/out.js', 'swarm.dart']);
    print('Run $command');
    var result = Process.runSync(
      Platform.resolvedExecutable,
      command,
      workingDirectory: tmpDir.path,
    );
    print('exit code: ${result.exitCode}');
    print('stdout:');
    print(result.stdout);
    print('stderr:');
    print(result.stderr);
    Expect.equals(0, result.exitCode);
    String output1 = File.fromUri(
      tmpDir.uri.resolve('without/out.js'),
    ).readAsStringSync();

    command = dart2JsCommand([
      '--out=json/out.js',
      'swarm.dart',
      '--stage=dump-info-all',
    ]);
    print('Run $command');
    result = Process.runSync(
      Platform.resolvedExecutable,
      command,
      workingDirectory: tmpDir.path,
    );
    print('exit code: ${result.exitCode}');
    print('stdout:');
    print(result.stdout);
    print('stderr:');
    print(result.stderr);
    Expect.equals(0, result.exitCode);
    String output2 = File.fromUri(
      tmpDir.uri.resolve('json/out.js'),
    ).readAsStringSync();
    String dumpInfoJson1 = File.fromUri(
      tmpDir.uri.resolve('json/out.js.info.json'),
    ).readAsStringSync();

    print('Compare outputs...');
    Expect.equals(output1, output2);

    command = dart2JsCommand([
      '--out=binary/out.js',
      'swarm.dart',
      '--dump-info=binary',
      '--stage=dump-info-all',
    ]);
    print('Run $command');
    result = Process.runSync(
      Platform.resolvedExecutable,
      command,
      workingDirectory: tmpDir.path,
    );
    print('exit code: ${result.exitCode}');
    print('stdout:');
    print(result.stdout);
    print('stderr:');
    print(result.stderr);
    Expect.equals(0, result.exitCode);
    String output3 = File.fromUri(
      tmpDir.uri.resolve('binary/out.js'),
    ).readAsStringSync();
    List<int> dumpInfoBinary1 = File.fromUri(
      tmpDir.uri.resolve('binary/out.js.info.data'),
    ).readAsBytesSync();

    print('Compare outputs...');
    Expect.equals(output1, output3);

    command = dart2JsCommand([
      '--cfe-only',
      '--out=json/cfe.dill',
      'swarm.dart',
    ]);
    print('Run $command');
    result = Process.runSync(
      Platform.resolvedExecutable,
      command,
      workingDirectory: tmpDir.path,
    );
    print('exit code: ${result.exitCode}');
    print('stdout:');
    print(result.stdout);
    print('stderr:');
    print(result.stderr);
    command = dart2JsCommand([
      '--input-dill=json/cfe.dill',
      '--closed-world-data=json/world.data',
      '--out=json/world.dill',
      '--stage=closed-world',
      'swarm.dart',
    ]);
    print('Run $command');
    result = Process.runSync(
      Platform.resolvedExecutable,
      command,
      workingDirectory: tmpDir.path,
    );
    print('exit code: ${result.exitCode}');
    print('stdout:');
    print(result.stdout);
    print('stderr:');
    print(result.stderr);
    command = dart2JsCommand([
      '--input-dill=json/world.dill',
      '--closed-world-data=json/world.data',
      '--global-inference-data=json/global.data',
      '--stage=global-inference',
      'swarm.dart',
    ]);
    print('Run $command');
    result = Process.runSync(
      Platform.resolvedExecutable,
      command,
      workingDirectory: tmpDir.path,
    );
    print('exit code: ${result.exitCode}');
    print('stdout:');
    print(result.stdout);
    print('stderr:');
    print(result.stderr);
    command = dart2JsCommand([
      '--input-dill=json/world.dill',
      '--closed-world-data=json/world.data',
      '--global-inference-data=json/global.data',
      '--codegen-data=codegen',
      '--codegen-shards=1',
      '--codegen-shard=0',
      '--stage=codegen',
      'swarm.dart',
    ]);
    print('Run $command');
    result = Process.runSync(
      Platform.resolvedExecutable,
      command,
      workingDirectory: tmpDir.path,
    );
    print('exit code: ${result.exitCode}');
    print('stdout:');
    print(result.stdout);
    print('stderr:');
    print(result.stderr);
    command = dart2JsCommand([
      '--input-dill=json/world.dill',
      '--closed-world-data=json/world.data',
      '--global-inference-data=json/global.data',
      '--codegen-data=codegen',
      '--codegen-shards=1',
      '--out=out.js',
      '--dump-info-data=json/dump.data',
      '--stage=emit-js',
      'swarm.dart',
    ]);
    print('Run $command');
    result = Process.runSync(
      Platform.resolvedExecutable,
      command,
      workingDirectory: tmpDir.path,
    );
    print('exit code: ${result.exitCode}');
    print('stdout:');
    print(result.stdout);
    print('stderr:');
    print(result.stderr);
    command = dart2JsCommand([
      '--input-dill=json/world.dill',
      '--closed-world-data=json/world.data',
      '--global-inference-data=json/global.data',
      '--codegen-data=codegen',
      '--codegen-shards=1',
      '--dump-info-data=json/dump.data',
      '--stage=dump-info',
      'swarm.dart',
    ]);
    print('Run $command');
    result = Process.runSync(
      Platform.resolvedExecutable,
      command,
      workingDirectory: tmpDir.path,
    );
    print('exit code: ${result.exitCode}');
    print('stdout:');
    print(result.stdout);
    print('stderr:');
    print(result.stderr);
    Expect.equals(0, result.exitCode);
    String output4 = File.fromUri(
      tmpDir.uri.resolve('json/out.js'),
    ).readAsStringSync();
    String dumpInfoJson2 = File.fromUri(
      tmpDir.uri.resolve('json/out.js.info.json'),
    ).readAsStringSync();

    command = dart2JsCommand([
      '--input-dill=json/world.dill',
      '--closed-world-data=json/world.data',
      '--global-inference-data=json/global.data',
      '--codegen-data=codegen',
      '--codegen-shards=1',
      '--dump-info-data=json/dump.data',
      '--dump-info=binary',
      '--stage=dump-info',
      'swarm.dart',
    ]);
    print('Run $command');
    result = Process.runSync(
      Platform.resolvedExecutable,
      command,
      workingDirectory: tmpDir.path,
    );
    print('exit code: ${result.exitCode}');
    print('stdout:');
    print(result.stdout);
    print('stderr:');
    print(result.stderr);
    Expect.equals(0, result.exitCode);
    String output5 = File.fromUri(
      tmpDir.uri.resolve('json/out.js'),
    ).readAsStringSync();
    List<int> dumpInfoBinary2 = File.fromUri(
      tmpDir.uri.resolve('binary/out.js.info.data'),
    ).readAsBytesSync();

    print('Compare outputs...');
    Expect.equals(output1, output4);
    Expect.equals(output1, output5);
    Expect.equals(dumpInfoJson1, dumpInfoJson2);
    Expect.listEquals(dumpInfoBinary1, dumpInfoBinary2);

    print('Done');
  } finally {
    print("Deleting '${tmpDir.path}'.");
    tmpDir.deleteSync(recursive: true);
  }
}
