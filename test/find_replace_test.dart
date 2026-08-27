import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jsomatter/presentation/controllers/home_page_controller.dart';
import 'package:jsomatter/presentation/controllers/logger_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.reset();
    Get.put(LoggerController());
  });

  test('Find mode and Replace mode open independently', () async {
    final controller = Get.put(HomePageController());
    await pumpEventQueue();

    expect(controller.isFindBarOpen.value, false);
    expect(controller.isReplaceMode.value, false);

    // Open Find Mode
    controller.openFindMode();
    await pumpEventQueue();
    expect(controller.isFindBarOpen.value, true);
    expect(controller.isReplaceMode.value, false);

    // Open Replace Mode
    controller.openReplaceMode();
    await pumpEventQueue();
    expect(controller.isFindBarOpen.value, true);
    expect(controller.isReplaceMode.value, true);

    // Toggle Replace Mode
    controller.toggleReplaceMode();
    await pumpEventQueue();
    expect(controller.isReplaceMode.value, false);

    // Close Find Bar
    controller.closeFindBar();
    await pumpEventQueue();
    expect(controller.isFindBarOpen.value, false);
  });

  test('Find matches respects Match Case toggle', () async {
    final controller = Get.put(HomePageController());
    await pumpEventQueue();

    const sample = 'JSON json Json JSon';

    // Case insensitive search (default)
    controller.isMatchCase.value = false;
    final matchesInsensitive = controller.findMatches(sample, 'json');
    expect(matchesInsensitive.length, 4);

    // Case sensitive search
    controller.isMatchCase.value = true;
    final matchesSensitive = controller.findMatches(sample, 'json');
    expect(matchesSensitive.length, 1);
    expect(sample.substring(matchesSensitive.first.start, matchesSensitive.first.end), 'json');
  });

  test('Find matches respects Match Whole Word toggle', () async {
    final controller = Get.put(HomePageController());
    await pumpEventQueue();

    const sample = 'json jsonObject myjson json';

    // Partial word search
    controller.isMatchWholeWord.value = false;
    final matchesPartial = controller.findMatches(sample, 'json');
    expect(matchesPartial.length, 4);

    // Whole word search
    controller.isMatchWholeWord.value = true;
    final matchesWhole = controller.findMatches(sample, 'json');
    expect(matchesWhole.length, 2);
  });

  test('Find matches respects Regular Expression toggle', () async {
    final controller = Get.put(HomePageController());
    await pumpEventQueue();

    const sample = 'user_101 user_202 user_abc';

    // Regex pattern matching numbers
    controller.isUseRegex.value = true;
    final matchesRegex = controller.findMatches(sample, r'user_\d+');
    expect(matchesRegex.length, 2);
  });

  test('Replace current match replaces specific match', () async {
    final controller = Get.put(HomePageController());
    await pumpEventQueue();

    controller.controller.text = 'hello world hello';
    controller.findQuery.value = 'hello';
    controller.replaceText.value = 'hi';
    controller.currentMatchIndex.value = 1;

    controller.replaceInController(controller.controller);
    expect(controller.controller.text, 'hi world hello');
  });

  test('Replace All replaces all match occurrences in editor text', () async {
    final controller = Get.put(HomePageController());
    await pumpEventQueue();

    controller.controller.text = 'apple banana apple cherry apple';
    controller.findQuery.value = 'apple';
    controller.replaceText.value = 'orange';

    controller.replaceAllInController(controller.controller);
    expect(controller.controller.text, 'orange banana orange cherry orange');
  });
}
