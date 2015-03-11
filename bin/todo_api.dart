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

library todomvc.api;

import "dart:async";

import "package:gcloud_dart_todos/models.dart";
import "package:rpc/rpc.dart";

import "todo_dao.dart";

/// Name of the RPC API.
const String apiName = "todomvc_api";

/// Version of the RPC API.
const String apiVersion = "v1";

/// Prefix for requests to the [Todo] collection.
const String todoCollectionPrefix = "todos";

/// Handles the mapping for the Todo MVC API.
@ApiClass(name: apiName, version: apiVersion)
class TodoApi {

  // [Todo] DAO implementation to inject.
  final TodoDao _todoDao;

  TodoApi(this._todoDao);

  /// Returns all todos.
  @ApiMethod(path: todoCollectionPrefix)
  Future<List<Todo>> getAllTodos() async {
    return _todoDao.getAll();
  }

  /// Returns the requested todo.
  @ApiMethod(path: "$todoCollectionPrefix/{id}")
  Future<Todo> getTodo(int id) {
    return _todoDao.get(id);
  }

  /// Adds a todo.
  @ApiMethod(path: todoCollectionPrefix, method: "POST")
  Future<Todo> createTodo(Todo request) {
    request.id = null;
    request.completed = false;
    return _todoDao.write(request);
  }

  /// Updates the given todo.
  @ApiMethod(path: "$todoCollectionPrefix/{id}", method: "PUT")
  Future<Todo> updateTodo(int id, Todo request) {
    request.id = id;
    return _todoDao.write(request);
  }

  /// Deletes completed todos.
  @ApiMethod(path: todoCollectionPrefix, method: "DELETE")
  Future<VoidMessage> deleteCompletedTodos() {
    return _todoDao.deleteCompleted();
  }

  /// Deletes the given todo.
  @ApiMethod(path: "$todoCollectionPrefix/{id}", method: "DELETE")
  Future<VoidMessage> deleteTodo(int id) {
    return _todoDao.delete(id);
  }
}
