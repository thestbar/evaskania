// Driver shim so integration_test/detection_regression_test.dart can also
// run in profile mode (Flutter Driver refuses --release, but profile builds
// go through the same R8/ProGuard minification as release):
//
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/detection_regression_test.dart \
//     -d <device> --profile
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
