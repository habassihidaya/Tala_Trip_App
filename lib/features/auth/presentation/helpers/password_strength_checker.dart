import 'package:zxcvbnm/languages/ar.dart' as ar;
import 'package:zxcvbnm/languages/en.dart' as en;
import 'package:zxcvbnm/languages/fr.dart' as fr;
import 'package:zxcvbnm/zxcvbnm.dart';

import '../../domain/validation/auth_validation.dart';

class PasswordStrengthChecker {
  final Zxcvbnm _estimator = Zxcvbnm(
    dictionaries: {...ar.dictionaries, ...en.dictionaries, ...fr.dictionaries},
  );

  int? score(String password, {List<String> userInputs = const []}) {
    if (password.isEmpty ||
        password.runes.length > AuthValidation.maxPasswordLength) {
      return null;
    }

    return _estimator(password, userInputs).score;
  }
}
