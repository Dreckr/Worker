import 'dart:async';
import 'package:worker/worker.dart';
import 'package:unittest/unittest.dart';
import 'package:unittest/vm_config.dart';

void main () {
  useVMConfiguration();
  
  group('Worker construction', () {
    Worker worker;
    
    test('with empty constructor', () {
      worker = new Worker();
      expect(worker.poolSize, equals(1));
      expect(worker.availableSendPorts, isEmpty);
      expect(worker.workingSendPorts, isEmpty);
    });
    
    test('with poolSize parameter constructor', () {
      int poolSize = 4; 
      worker = new Worker(poolSize: poolSize);
      expect(worker.poolSize, equals(poolSize));
      expect(worker.availableSendPorts, isEmpty);
      expect(worker.workingSendPorts, isEmpty);
    });
  });
  
  group ('Task execution', () {
    Worker worker;
    Task task;
    
    setUp(() {
      worker = new Worker();
    });
    
    test('of sync task', () {
      task = new AddTask(1, 2);
      
      worker.execute(task).then(expectAsync1((result) {
        expect(result, isNotNull);
        expect(result, equals(3));
      }));
    });
    
//  This won't work until Dart's issue 9315 is solved
//  http://code.google.com/p/dart/issues/detail?id=9315
//    test('of sync task with exception', () {
//      task = new AddTask(1, 2, throwException: true);
//      
//    
//      worker.execute(task).then((result) {
//      },
//      onError: expectAsync1((error) {
//        expect(error, isNotNull);
//      })
//      );
//    });
    
    test('of async task', () {
      task = new AsyncAddTask(3, 2);
      
      worker.execute(task).then(expectAsync1((result) {
        expect(result, isNotNull);
        expect(result, equals(5));
      }));
    });
    
//  This won't work until Dart's issue 9315 is solved
//  http://code.google.com/p/dart/issues/detail?id=9315
//    test('of sync task with exception', () {
//      task = new AsyncAddTask(1, 2, throwException: true);
//      
//    
//      worker.execute(task).then((result) {
//      },
//      onError: expectAsync1((error) {
//        expect(error, isNotNull);
//      })
//      );
//    });
    
// TODO Isolate pooling tests
  });
}

class AddTask implements Task {
  int x, y;
  bool throwException;
  
  AddTask (this.x, this.y, {this.throwException: false});
  
  int execute () {
    if (this.throwException)
      throw new Exception('Test Future Exception');
    else
      return x + y; 
  }
}

class AsyncAddTask implements Task {
  int x, y;
  bool throwException;
  
  AsyncAddTask (this.x, this.y, {this.throwException: false});
  
  Future execute () {
    Completer completer = new Completer();
    
    runAsync(() { 
      if (this.throwException)
        completer.completeError(new Exception('Test Async Exception'));
      else
        completer.complete(x + y);
      });
    
    return completer.future;
  }
  
}

