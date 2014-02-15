library worker.test.stress;

import 'dart:async';
import 'dart:io';
import 'package:worker/worker.dart';
import 'package:unittest/unittest.dart';

void stressTest() {
  group("Stress test:", () {
    Worker worker;
    
    setUp(() {
      worker = new Worker();
    });
    
    tearDown(() {
      worker.close();
    });
    
    test("Run single long running task", () {
      var future = worker.handle(new LongRunningTask());
      
      expect(future, completes);
    });
    
    test("Run one long running task for each processor", () {
      var futures = [];
      
      for (var i = 0; i < Platform.numberOfProcessors; i++) {
        futures.add(worker.handle(new LongRunningTask()));
      }
      
      expect(Future.wait(futures), completes);
    });
    
    test("Run more long running tasks than available processors", () {
      var futures = [];
      
      for (var i = 0; i < Platform.numberOfProcessors *2; i++) {
        futures.add(worker.handle(new LongRunningTask()));
      }
      
      expect(Future.wait(futures), completes);
    });
  });
}

class LongRunningTask extends Task {
  
  bool execute() {
    var stopWatch = new Stopwatch();
    stopWatch.start();
    
    while(stopWatch.elapsedMilliseconds < 1000);
    stopWatch.stop();
    
    return true;
  }
} 