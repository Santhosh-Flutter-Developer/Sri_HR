import 'dart:math';

class OtpGenerator {
  static String generate({int length = 6}) {
    final rng = Random.secure();
    return List.generate(length, (_) => rng.nextInt(10)).join();
  }
}