// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';

class CancelRequestHandler extends SharedMessageHandler<CancelParams, void> {
  final Map<String, CancelableToken> _tokens = {};

  CancelRequestHandler(super.server);

  @override
  Method get handlesMessage => Method.cancelRequest;

  @override
  LspJsonHandler<CancelParams> get jsonHandler => CancelParams.jsonHandler;

  @override
  // Cancellation is only currently supported for the native protocol clients.
  // Supporting cancellation for other clients (such as over DTD) may require
  // separation of requests so they can only cancel their own.
  bool get requiresTrustedCaller => true;

  void clearToken(RequestMessage message) {
    _tokens.remove(message.id.toString());
  }

  CancelableToken createToken(RequestMessage message) {
    var token = CancelableToken();
    _tokens[message.id.toString()] = token;
    return token;
  }

  @override
  ErrorOr<void> handle(
    CancelParams params,
    MessageInfo message,
    CancellationToken token,
  ) {
    // Don't assume this is in the map as it's possible the client sent a
    // cancellation that we processed after already starting to send the
    // response and cleared the token.
    _tokens[params.id.toString()]?.cancel();
    return success(null);
  }
}
