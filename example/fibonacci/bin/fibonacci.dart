import "package:worker/worker.dart";
import "dart:async";

void main() {
  final worker = new Worker();
  var futures = [];
  
  for (var i in [10, 20, 30, 40, 30, 20]) {
    futures.add(worker.handle(new FibTask(i)));
  }

  Future.wait(futures).then((r) {
    print(r);
    worker.close();
  });
}

int fib(int n) {
  if (n == 0) return 0;
  if (n == 1) return 1;
  return fib(n-1) + fib(n-2);
}

class FibTask extends Task {
  int _v;
  FibTask(this._v);
  execute() => fib(_v);
}