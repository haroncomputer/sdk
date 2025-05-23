// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Conventions for paths:
///
/// - Use the [Uri] class for paths that may have the `file`, `dart` or
///   `package` scheme.  Never use [Uri] for relative paths.
/// - Use [String]s for all filenames and paths that have no scheme prefix.
/// - Never translate a `dart:` or `package:` URI into a `file:` URI, instead
///   translate it to a [String] if the file system path is needed.
/// - Only use [File] from dart:io at the last moment when it is needed.
///
library kernel;

import 'dart:typed_data';

import 'ast.dart';
import 'binary/ast_to_binary.dart';
import 'binary/ast_from_binary.dart';
import 'dart:io';
import 'text/ast_to_text.dart';

export 'ast.dart';

Component loadComponentFromBinary(String path, [Component? component]) {
  Uint8List bytes = new File(path).readAsBytesSync();
  return loadComponentFromBytes(bytes, component);
}

Component loadComponentFromBytes(Uint8List bytes, [Component? component]) {
  component ??= new Component();
  new BinaryBuilder(bytes).readComponent(component);
  return component;
}

Component loadComponentSourceFromBytes(Uint8List bytes,
    [Component? component]) {
  component ??= new Component();
  new BinaryBuilder(bytes).readComponentSource(component);
  return component;
}

Future writeComponentToBinary(Component component, String path,
    {bool includeSource = true}) {
  IOSink sink;
  if (path == 'null' || path == 'stdout') {
    sink = stdout.nonBlocking;
  } else {
    sink = new File(path).openWrite();
  }

  Future future;
  try {
    new BinaryPrinter(sink, includeSources: includeSource)
        .writeComponentFile(component);
  } finally {
    if (sink == stdout.nonBlocking) {
      future = sink.flush();
    } else {
      future = sink.close();
    }
  }

  return future;
}

Uint8List writeComponentToBytes(Component component) {
  BytesSink sink = new BytesSink();
  new BinaryPrinter(sink).writeComponentFile(component);
  return sink.builder.toBytes();
}

void writeComponentToText(Component component,
    {String? path, bool showOffsets = false, bool showMetadata = false}) {
  StringBuffer buffer = new StringBuffer();
  new Printer(buffer, showOffsets: showOffsets, showMetadata: showMetadata)
      .writeComponentFile(component);
  if (path == null) {
    print(buffer);
  } else {
    new File(path).writeAsStringSync('$buffer');
  }
}
