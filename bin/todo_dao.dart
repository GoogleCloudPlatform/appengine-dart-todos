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

library todomvc.server.dao;

import "dart:async";

import "package:gcloud/db.dart";
import "package:gcloud_dart_todos/models.dart";

/// Interface for reading and writing [Todo] objects to the persistence layers.
abstract class TodoDao {

  /// Get all [Todo]s.
  Future<List<Todo>> getAll() ;

  /// Get the [Todo] with the given [id].
  Future<Todo> get(int id);

  /// Create a [Todo] if the ID is `null` otherwise modify the given [Todo].
  Future<Todo> write(Todo todo);

  /// Deleted all completed [Todo]s.
  Future deleteCompleted();

  /// Delete the [Todo] with the given [id].
  Future delete(int id);

}

/// Handles reading and writing [Todo] objects to the Cloud Datastore.
class TodoDaoAppEngineImpl implements TodoDao {

  /// Returns the Key of the root element for all Todos.
  Key get _rootKey => dbService.emptyKey.append(TodoRoot, id: 1);

  Future<List<Todo>> getAll() {
    var query = dbService.query(Todo, ancestorKey: _rootKey);
    return query.run().toList();
  }

  Future<Todo> get(int id) async {
    Todo model = new Todo()
      ..id = id
      ..parentKey = _rootKey;
    List<Todo> todos = await dbService.lookup([model.key]);
    return todos[0];
  }

  Future<Todo> write(Todo todo) async {
    todo.parentKey = _rootKey;
    await dbService.commit(inserts: [todo]);
    return todo;
  }

  Future deleteCompleted() async {
    // Begin transaction.
    return await dbService.withTransaction((Transaction tx) async {
      // Query the completed Todos.
      var query = tx.query(Todo, _rootKey)..filter("completed =", true);
      List<Todo> todos = await query.run().toList();
      // Get the list of Todos' keys.
      var keys = todos.fold([], (List l, Todo t) => l..add(t.key));
      if (keys.length == 0) return null;
      // Delete the completed Todos.
      tx.queueMutations(deletes: keys);
      return tx.commit();
    });
  }

  Future delete(int id) {
    Todo model = new Todo()..id = id;
    model.parentKey = _rootKey;
    return dbService.commit(deletes: [model.key]);
  }
}

/// Root for all [Todo]s.
@Kind()
class TodoRoot extends Model {
}
