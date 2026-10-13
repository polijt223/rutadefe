import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rutadefe/services/progress_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('section completion persists and derives seminar progress', () async {
    SharedPreferences.setMockInitialValues({});
    final progress = ProgressService();

    expect(
      await progress.setSectionCompleted(
        seminarioId: 'seminario-1',
        seccionId: 'seccion-1',
        totalSections: 2,
        completed: true,
      ),
      0.5,
    );
    expect(await progress.getProgressAsync('seminario-1'), 0.5);
    expect(await progress.isSectionCompleted('seminario-1', 'seccion-1'), isTrue);

    expect(
      await progress.setSectionCompleted(
        seminarioId: 'seminario-1',
        seccionId: 'seccion-2',
        totalSections: 2,
        completed: true,
      ),
      1.0,
    );
    expect(await progress.getCompletedSeminariosCount(), 1);
  });

  test('skips Firestore when Firebase is not initialized', () async {
    SharedPreferences.setMockInitialValues({});
    final progress = ProgressService();

    await progress.loadStoredProgress();
    expect(progress.getProgress('seminario-offline'), 0.0);

    expect(
      await progress.setSectionCompleted(
        seminarioId: 'seminario-offline',
        seccionId: 'seccion-1',
        totalSections: 1,
        completed: true,
      ),
      1.0,
    );
  });
}