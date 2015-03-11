// This file is MIT License.
// Copyright (c) Addy Osmani, Sindre Sorhus, Pascal Hartig, Stephen Sawchuk.
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.

part of todomvc;

class TodoApp {

  List<TodoWidget> todoWidgets = new List<TodoWidget>();

  Element todoListElement = querySelector('#todo-list');
  Element mainElement = querySelector('#main');
  InputElement checkAllCheckboxElement = querySelector('#toggle-all');
  Element footerElement = querySelector('#footer');
  Element countElement = querySelector('#todo-count');
  Element clearCompletedElement = querySelector('#clear-completed');
  Element showAllElement = querySelector('#filters a[href="#/"]');
  Element showActiveElement = querySelector('#filters a[href="#/active"]');
  Element showCompletedElement = querySelector('#filters a[href="#/completed"]');

  TodoApp() {
    loadTodos().then((_) {
      initElementEventListeners();

      window.onHashChange.listen((e) => updateFilter());

      updateFooterDisplay();
    });
  }

  Future loadTodos() {
    return getAllTodosApi().then((List<Todo> todos) {
      if (todos != null) {
        todos.forEach(addTodo);
      }
    });
  }

  void initElementEventListeners() {
    InputElement newTodoElement = querySelector('#new-todo');

    newTodoElement.onKeyDown.listen((KeyboardEvent e) {
      if (e.keyCode == KeyCode.ENTER) {
        var title = newTodoElement.value.trim();
        if (title.isNotEmpty) {
          newTodoElement.value = '';
          createTodoApi(title).then((Todo newTodo) {
            addTodo(newTodo);
            updateFooterDisplay();
          });
        }
      }
    });

    checkAllCheckboxElement.onClick.listen((e) {
      for (var todoWidget in todoWidgets) {
        if (todoWidget.todo.completed != checkAllCheckboxElement.checked) {
          todoWidget.toggle();
          updateTodoApi(todoWidget.todo);
        }
      }
      updateCounts();
    });

    clearCompletedElement.onClick.listen((_) {
      var newList = new List<TodoWidget>();
      for (TodoWidget todoWidget in todoWidgets) {
        if (todoWidget.todo.completed) {
          todoWidget.element.remove();
        } else {
          newList.add(todoWidget);
        }
      }
      todoWidgets = newList;
      updateFooterDisplay();
      clearCompletedApi();
    });
  }

  void addTodo(Todo todo) {
    var todoWidget = new TodoWidget(this, todo);
    todoWidgets.add(todoWidget);
    todoListElement.nodes.add(todoWidget.createElement());
  }

  void updateFooterDisplay() {
    var display = todoWidgets.length == 0 ? 'none' : 'block';
    checkAllCheckboxElement.style.display = display;
    mainElement.style.display = display;
    footerElement.style.display = display;
    updateCounts();
  }

  void updateCounts() {
    var complete = todoWidgets.where((w) => w.todo.completed).length;
    checkAllCheckboxElement.checked = (complete == todoWidgets.length);
    var left = todoWidgets.length - complete;
    countElement.innerHtml = '<strong>$left</strong> item${left != 1 ? 's' : ''} left';
    if (complete == 0) {
      clearCompletedElement.style.display = 'none';
    } else {
      clearCompletedElement.style.display = 'block';
      clearCompletedElement.text = 'Clear completed ($complete)';
    }
    updateFilter();
  }

  Future removeTodo(TodoWidget todoWidget) {
    todoWidgets.removeAt(todoWidgets.indexOf(todoWidget));
    return deleteTodoApi(todoWidget.todo.id);
  }

  void updateFilter() {
    switch(window.location.hash) {
      case '#/active':
        showActive();
        break;
      case '#/completed':
        showCompleted();
        break;
      default:
        showAll();
        return;
    }
  }

  void showAll() {
    setSelectedFilter(showAllElement);
    for (var todoWidget in todoWidgets) {
      todoWidget.visible = true;
    }
  }

  void showActive() {
    setSelectedFilter(showActiveElement);
    for (var todoWidget in todoWidgets) {
      todoWidget.visible = !todoWidget.todo.completed;
    }
  }

  void showCompleted() {
    setSelectedFilter(showCompletedElement);
    for (var todoWidget in todoWidgets) {
      todoWidget.visible = todoWidget.todo.completed;
    }
  }

  void setSelectedFilter(Element e) {
    showAllElement.classes.remove('selected');
    showActiveElement.classes.remove('selected');
    showCompletedElement.classes.remove('selected');
    e.classes.add('selected');
  }

  // =============== TodoMVC Server API ================

  // Sends the given [data] to to the TodoMVC Server API. The [data] will be
  // encoded to JSON before being sent. The response text will be passed to the
  // [processResponse] callback.
  Future _sendApiRequest(String method, String uri, {var data: null,
                         processResponse(String data): null}) {
    var completer = new Completer();
    var request = new HttpRequest();
    request.open(method, uri);
    request.onLoadEnd.listen((_) {
      completer.complete(processResponse(request.responseText));
    });
    request.send(data == null ? null : JSON.encode(data));
    return completer.future;
  }

  /// Creates a new [Todo] with the given title and returns the created [Todo].
  Future<Todo> createTodoApi(String title) =>
      _sendApiRequest('POST', '/todos', data: {"title": title}, processResponse:
          (String response) => new Todo.fromJson(JSON.decode(response)));

  /// Updates the given [Todo] on the server and returns the updated [Todo].
  Future<Todo> updateTodoApi(Todo todo) =>
      _sendApiRequest('PUT', '/todos/${todo.id}', data: todo, processResponse:
          (String response) => new Todo.fromJson(JSON.decode(response)));

  /// Returns all [Todo]s from the server.
  Future<List<Todo>> getAllTodosApi() =>
      _sendApiRequest('GET', '/todos', processResponse:
          (String response) {
            List todosAsMap = JSON.decode(response);
            var resp = [];
            for (Map todoAsMap in todosAsMap) {
              resp.add(new Todo.fromJson(todoAsMap));
            }
            return resp;
      });

  /// Deletes the [Todo] of the given [id].
  Future deleteTodoApi(int id) => _sendApiRequest('DELETE', '/todos/$id');

  /// Clears all completed [Todo]s on the server.
  Future clearCompletedApi() => _sendApiRequest('DELETE', '/todos');

}
