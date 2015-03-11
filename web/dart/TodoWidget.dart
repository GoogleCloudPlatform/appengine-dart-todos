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

class TodoWidget {

  static const HtmlEscape htmlEscape = const HtmlEscape();

  TodoApp todoApp;
  Todo todo;
  Element element;
  InputElement toggleElement;

  TodoWidget(this.todoApp, this.todo);

  Element createElement() {
    element = new Element.html('''
      <li ${todo.completed ? 'class="completed"' : ''}>
      <div class='view'>
      <input class='toggle' type='checkbox' ${todo.completed ? 'checked' : ''}>
      <label class='todo-content'>${htmlEscape.convert(todo.title)}</label>
      <button class='destroy'></button>
      </div>
      <input class='edit' value='${htmlEscape.convert(todo.title)}'>
      </li>
    ''');

    Element contentElement = element.querySelector('.todo-content');
    InputElement editElement = element.querySelector('.edit');

    toggleElement = element.querySelector('.toggle');

    toggleElement.onClick.listen((_) {
      toggle();
      todoApp.updateCounts();
      todoApp.updateTodoApi(todo);
    });

    contentElement.onDoubleClick.listen((_) {
      element.classes.add('editing');
      editElement.selectionStart = todo.title.length;
      editElement.focus();
    });

    void removeTodo() {
      element.remove();
      todoApp.removeTodo(this).then((_) => todoApp.updateFooterDisplay());
    }

    element.querySelector('.destroy').onClick.listen((_) {
      removeTodo();
    });

    void doneEditing() {
      editElement.value = editElement.value.trim();
      todo.title = editElement.value;
      if (todo.title.isNotEmpty) {
        contentElement.text = todo.title;
        element.classes.remove('editing');
        todoApp.updateTodoApi(todo);
      } else {
        removeTodo();
      }
    }

    void undoEditing() {
      element.classes.remove('editing');
      editElement.value = todo.title;
    }

    bool blurBubble = false;
    editElement
      ..onKeyDown.listen((KeyboardEvent e) {
        switch (e.keyCode) {
          case KeyCode.ENTER:
            blurBubble = true;
            doneEditing();
            break;
          case KeyCode.ESC:
            blurBubble = true;
            undoEditing();
            break;
        }
      })
      ..onBlur.listen((_) {
        if (blurBubble) blurBubble = false;
        else doneEditing();
      });

    return element;
  }

  void set visible(bool visible) {
    element.style.display = visible ? 'block' : 'none';
  }

  void toggle() {
    todo.completed = !todo.completed;
    toggleElement.checked = todo.completed;
    if (todo.completed) {
      element.classes.add('completed');
    } else {
      element.classes.remove('completed');
    }
  }
}
