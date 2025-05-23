// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Generates a wrapper around dart2js to ship with the SDK.
///
/// The only reason to create this wrapper is to be able to embed the sdk
/// version information into the compiler.
import 'dart:io';
import 'dart:async';

Future<String> getVersion(var rootPath, bool noGitHash) {
  var printVersionScript = rootPath.resolve("tools/make_version.py");
  var args = <String>[
    printVersionScript.toFilePath(),
    "--quiet",
    if (noGitHash) '--no-git-hash',
  ];
  return Process.run("python3", args, runInShell: true).then((result) {
    if (result.exitCode != 0) {
      throw "Could not generate version: ${args.join(' ')}"
          "\n${result.stdout}\n${result.stderr}";
    }
    return result.stdout.trim();
  });
}

Future<String> getDart2jsSnapshotGenerationFile(var rootPath, bool noGitHash) {
  return getVersion(rootPath, noGitHash).then((version) {
    var snapshotGenerationText =
        """
import 'package:compiler/src/dart2js.dart' as dart2jsMain;

void main(List<String> arguments) {
  dart2jsMain.buildID = "$version";
  dart2jsMain.main(arguments);
}
""";
    return snapshotGenerationText;
  });
}

/**
 * Takes the following arguments:
 * --output_dir=val     The full path to the output_dir.
 * --dart2js_main=val   The path to the dart2js main script relative to root.
 * --no-git-hash        Omit the git hash in the output.
 */
void main(List<String> arguments) {
  bool noGitHash = false;
  var validArguments = ["--output_dir", "--dart2js_main"];
  var args = {};
  for (var argument in arguments) {
    if (argument == '--no-git-hash') {
      noGitHash = true;
      continue;
    }
    var argumentSplit = argument.split("=");
    if (argumentSplit.length != 2) throw "Invalid argument $argument, no =";
    if (!validArguments.contains(argumentSplit[0])) {
      throw "Invalid argument $argument";
    }
    args[argumentSplit[0].substring(2)] = argumentSplit[1];
  }
  if (!args.containsKey("output_dir")) throw "Please specify output_dir";

  var scriptFile = Uri.base.resolveUri(Platform.script);
  var path = scriptFile.resolve(".");
  var rootPath = path.resolve("../..");

  getDart2jsSnapshotGenerationFile(rootPath, noGitHash).then((result) {
    var wrapper = "${args['output_dir']}/dart2js.dart";
    new File(wrapper).writeAsStringSync(result);
  });
}
