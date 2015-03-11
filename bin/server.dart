// Copyright 2015 Google Inc
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// You may obtain a copy of the License at
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

library todomvc.server;

import "package:appengine/appengine.dart";
import "package:rpc/rpc.dart";
import "package:shelf/shelf.dart" as shelf;
import "package:shelf_appengine/shelf_appengine.dart" as shelf_ae;
import "package:shelf_rpc/shelf_rpc.dart" as shelf_rpc;

import "todo_api.dart";
import "todo_dao.dart";

main() {
  // We need App Engine services to access the Datastore.
  withAppEngineServices(() {
    // Instantiate the RPC API server.
    ApiServer apiServer = new ApiServer("", prettyPrint: true)
      ..addApi(new TodoApi(new TodoDaoAppEngineImpl()));

    // Cascading our Requests Handlers
    var cascade = new shelf.Cascade()
        .add(shelf_ae.assetHandler(
            directoryIndexServeMode: shelf_ae.DirectoryIndexServeMode.SERVE))
        .add(shelf_rpc.createRpcHandler(apiServer));

    // Adding a logger middleware and a URL re-writer for the RPC API.
    var handler = const shelf.Pipeline()
        .addMiddleware(shelf.logRequests())
        .addMiddleware(_rpcApiRewriter)
        .addHandler(cascade.handler);

    // Start serving with GAE.
    return shelf_ae.serve(handler);
  });
}

// Rewrites the URLs so that /todos is mapped to what the RPC API package
// expects for URLs which is /todomvc_api/v1/todos.
shelf.Handler _rpcApiRewriter(shelf.Handler innerHandler) {
  return (shelf.Request request) {
    if (request.url.path.startsWith("/$todoCollectionPrefix")) {
      request = request.change(
          url: Uri.parse("/$apiName/$apiVersion${request.url.path}"));
    }
    return innerHandler(request);
  };
}
