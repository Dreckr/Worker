library worker.test;

import 'package:unittest/vm_config.dart';
import 'construction_test.dart';
import 'execution_test.dart';
import 'stress_test.dart';

void main () {
  useVMConfiguration();
  
  constructionTest();
  executionTest();
  stressTest();

}
