import 'dart:async';
import 'dart:io';
import 'package:http_server/http_server.dart';
import 'package:mustache/mustache.dart' as Mustache;
import 'package:worker/worker.dart';

VirtualDirectory directory = new VirtualDirectory("static");
Worker worker = new Worker(poolSize: Platform.numberOfProcessors, 
                           spawnLazily: false);

Mustache.Template template;
void main() {
  HttpServer.bind("0.0.0.0", 9999).then(
      (server) {
        server.listen((request) {
          if (request.uri.path == "/" || 
              request.uri.path == "/templates/template.html") {
            serveTemplate(request);
          } else {
            serveRequest(request);
          }
        });
      }
  );
}

void serveRequest(HttpRequest request) {
  directory.serveRequest(request);
}

void serveTemplate(HttpRequest request) {
  worker.handle(new MustacheTask()).then((output) {
    request.response.headers.set("Content-Type", "text/html");
    request.response.write(output);
    request.response.close();
  });
}


String render(Mustache.Template template) {
  return template.renderString(values, lenient: true);
}

class MustacheTask extends Task {
  
  MustacheTask();
  
  Future<String> execute() {

    var completer = new Completer<String>();
    
    if (template == null) {
      var file = new File("static/templates/template.html");
      file.readAsString().then((content) {
        template = Mustache.parse(content);
        
        completer.complete(render(template));
      });
    } else {
      completer.complete(render(template));
    }
    
    return completer.future;
  }
}

var values = {
              
  "title": "WorkerMustache",
  
  "description": "This is a description",
  
  "author": "I am the author",
  
  "navs": [
    {"id": "home", "state": "active", "name": "Home"},
    {"id": "foo", "state": "", "name": "Foo"},
    {"id": "bar", "state": "", "name": "Bar"},
    {"id": "quux", "state": "", "name": "Quux"},
    {"id": "baz", "state": "", "name": "Baz"}
  ],
  
  "carousel-items": [
    { "state": "active",
      "image": "holder.js/900x500/auto/#777:#7a7a7a/text:Dart is awesome",
      "headline": "Dart is awesome",  
      "caption": "Cras justo odio, dapibus ac facilisis in, egestas eget quam. "
                 "Donec id elit non mi porta gravida at eget metus. "
                 "Nullam id dolor id nibh ultricies vehicula ut id elit."},
    { "state": "",
      "image": 
        "holder.js/900x500/auto/#666:#6a6a6a/text:Worker came from heaven", 
      "headline": "Worker came from heaven",  
      "caption": "Cras justo odio, dapibus ac facilisis in, egestas eget quam. "
                 "Donec id elit non mi porta gravida at eget metus. "
                 "Nullam id dolor id nibh ultricies vehicula ut id elit."},
    { "state": "",
      "image": 
        "holder.js/900x500/auto/#555:#5a5a5a/text:Mustache makes you look nice", 
      "headline": "Mustache makes you look nice",  
      "caption": "Cras justo odio, dapibus ac facilisis in, egestas eget quam. "
                 "Donec id elit non mi porta gravida at eget metus. "
                 "Nullam id dolor id nibh ultricies vehicula ut id elit."}
  ],
  
  "headings": [
    { "title": "Heading 1",
      "description": "Donec sed odio dui. Etiam porta sem malesuada magna "
                     "mollis euismod. Nullam id dolor id nibh ultricies "
                     "vehicula ut id elit. Morbi leo risus, porta ac "
                     "consectetur ac, vestibulum at eros. Praesent commodo "
                     "cursus magna."},
    { "title": "Heading 2",
      "description": "Donec sed odio dui. Etiam porta sem malesuada magna "
                     "mollis euismod. Nullam id dolor id nibh ultricies "
                     "vehicula ut id elit. Morbi leo risus, porta ac "
                     "consectetur ac, vestibulum at eros. Praesent commodo "
                     "cursus magna."},
    { "title": "Heading 3",
      "description": "Donec sed odio dui. Etiam porta sem malesuada magna "
                     "mollis euismod. Nullam id dolor id nibh ultricies "
                     "vehicula ut id elit. Morbi leo risus, porta ac "
                     "consectetur ac, vestibulum at eros. Praesent commodo "
                     "cursus magna."}
  ]
};
