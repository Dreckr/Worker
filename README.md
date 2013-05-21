Worker
====

An easy to use utility to perform tasks concurrently.

By performing blocking CPU intensive tasks concurrently, you free your main isolate 
to do other stuff while you take advantage of the CPU capabilities.

Usage
-----

To use this library, create a new Worker to handle that will handle the isolates for you, 
encapsulate your task in class that implements the Task interface and pass to the Worker 
to execute it:

```dart
void main () {
	Worker worker = new Worker();
	Task task = new AckermannTask(1, 2);
	worker.execute(task).then((result) => print(result));
}

class AckermannTask implements Task {
  int x, y;

  AckermannTask (this.x, this.y);

  int execute () {
    return ackermann(x, y);
  }

  int ackermann (int m, int n) {
    if (m == 0)
      return n+1;
    else if (m > 0 && n == 0)
      return ackermann(m-1, 1);
    else
      return ackermann(m-1, ackermann(m, n-1));
  }
}
```

You can also define how many tasks a worker can execute concurrently by defining the
size of its pool of isolates.

```dart
Worker worker = new Worker(poolSize: 4);
```

Tips
----
* A Task may return a Future. The Worker will wait until this Future is completed and will return its result.
* If you have perform many iterations of an operation, you can batch it into tasks and run them concurrently.
* Running tasks in other isolates involves in copying the task object to the other isolate. Keep your task thin.