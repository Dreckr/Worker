import 'package:worker/worker.dart';

void main () {
  Stopwatch sw = new Stopwatch();
  sw.start();
  Worker worker = new Worker(poolSize : 4);
  worker.execute(new AckermannTask(3, 10)).then((result) => print(sw.elapsed));
  worker.execute(new AckermannTask(3, 10)).then((result) => print(sw.elapsed));
  worker.execute(new AckermannTask(3, 10)).then((result) => print(sw.elapsed));
  worker.execute(new AckermannTask(3, 10)).then((result) => print(sw.elapsed));
  worker.execute(new AckermannTask(3, 10)).then((result) => print(sw.elapsed));
  worker.execute(new AckermannTask(3, 10)).then((result) => print(sw.elapsed));
  worker.execute(new AckermannTask(3, 10)).then((result) => print(sw.elapsed));
  worker.execute(new AckermannTask(3, 10)).then((result) => print(sw.elapsed));
  worker.execute(new AckermannTask(3, 10)).then((result) => print(sw.elapsed));
  worker.execute(new AckermannTask(3, 10)).then((result) => print(sw.elapsed));
  worker.execute(new AckermannTask(3, 10)).then((result) => print(sw.elapsed));
  worker.execute(new AckermannTask(3, 10)).then((result) => print(sw.elapsed));
  worker.execute(new AckermannTask(3, 10)).then((result) => print(sw.elapsed));
  worker.execute(new AckermannTask(3, 10)).then((result) => print(sw.elapsed));
  worker.execute(new AckermannTask(3, 10)).then((result) => print(sw.elapsed));
  worker.execute(new AckermannTask(3, 10)).then((result) => print(sw.elapsed));
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