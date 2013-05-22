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
      expect(worker.isolates, isEmpty);
      expect(worker.availableIsolates, isEmpty);
      expect(worker.workingIsolates, isEmpty);
    });
    
    test('with poolSize parameter constructor', () {
      int poolSize = 4; 
      worker = new Worker(poolSize: poolSize);
      expect(worker.poolSize, equals(poolSize));
      expect(worker.isolates, isEmpty);
      expect(worker.availableIsolates, isEmpty);
      expect(worker.workingIsolates, isEmpty);
    });
    
    test('with spawnLazily parameter constructor', () {
      worker = new Worker(spawnLazily: false);
      expect(worker.poolSize, equals(1));
      expect(worker.isolates, hasLength(1));
      expect(worker.availableIsolates, hasLength(1));
      expect(worker.workingIsolates, isEmpty);
    });
    
    test('with poolSize and spawnLazily parameters constructor', () {
      int poolSize = 4; 
      worker = new Worker(poolSize: poolSize, spawnLazily: false);
      expect(worker.poolSize, poolSize);
      expect(worker.isolates, hasLength(poolSize));
      expect(worker.availableIsolates, hasLength(poolSize));
      expect(worker.workingIsolates, isEmpty);
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
      
      worker.handle(task).then(expectAsync1((result) {
        expect(result, isNotNull);
        expect(result, equals(3));
      }));
    });
    
    test('of sync task with exception', () {
      task = new AddTask(1, 2, throwException: true);
      
    
      worker.handle(task).then((result) {
      },
      onError: expectAsync1((error) {
        expect(error, isNotNull);
      })
      );
    });
    
    test('of async task', () {
      task = new AsyncAddTask(3, 2);
      
      worker.handle(task).then(expectAsync1((result) {
        expect(result, isNotNull);
        expect(result, equals(5));
      }));
    });
    
    test('of sync task with exception', () {
      task = new AsyncAddTask(1, 2, throwException: true);
      
    
      worker.handle(task).then((result) {
      },
      onError: expectAsync1((error) {
        expect(error, isNotNull);
      })
      );
    });
    
// TODO Isolate pooling tests
// TODO Close isolate tests
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

