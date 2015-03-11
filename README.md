# appengine-dart-todos
> [TodoMVC](http://todomvc.com) backend and frontend using the [appengine](https://pub.dartlang.org/packages/appengine) Dart package.

## Prerequisites

1. Create a new cloud project on [console.developers.google.com](http://console.developers.google.com)
2. Note your **Project ID**. You will need it later.

FYI: You can view the content of your project's Cloud Datastore on the Google
Developers Console in **Storage > Cloud Datastore > Query** after adding your
first Todos.

## Running and deploying

You need to [install boot2docker](http://boot2docker.io/) and then install and
setup the Google Cloud SDK:

```sh
# Get gcloud
$ curl https://sdk.cloud.google.com | bash

# Authorize gcloud and set your default project
$ gcloud auth login
$ gcloud config set project <Project ID>

# Get App Engine component
$ gcloud components update app

# Check that Docker is running
$ boot2docker up
$ $(boot2docker shellinit)

# Download the Dart Docker image
$ docker pull google/dart-runtime
```

To run the app locally:

```sh
$ gcloud preview app run app.yaml
```

To open the app locally visit `http://localhost:8080`.

To deploy the app to production:

```sh
$ gcloud preview app deploy app.yaml
```

To open the app on production visit `http://<Project ID>.appspot.com`.

## Notes

The frontend code located in `/web` and `/lib` is a copy of the
[Vanilla Dart](https://github.com/tastejs/todomvc/tree/master/examples/vanilladart)
version of the TodoMVC frontend and adapted to use the TodoMVC Server API
handlers.
