// Cloud Functions has no Windows plugin. flutter analyze on Windows reports
// uri_does_not_exist even though Android/iOS builds resolve the package.
// ignore_for_file: uri_does_not_exist, undefined_identifier

import 'package:cloud_functions/cloud_functions.dart';

class QuizAdminService {
  Future<int> migrateAnswerKeys() async {
    final result = await FirebaseFunctions.instance
        .httpsCallable('migrateQuizAnswerKeys')
        .call<Map<String, dynamic>>();
    return result.data['migrated'] as int? ?? 0;
  }
}
