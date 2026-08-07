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

  test('Tabs initialize with random keywords and unique IDs', () async {
    final controller = Get.put(HomePageController());
    await pumpEventQueue();

    expect(controller.tabsIndex.length, 1);
    final initialTab = controller.selected;
    expect(initialTab.name, isNotNull);
    expect(initialTab.name.toString().isNotEmpty, true);
    expect(initialTab.id, isNotNull);
  });

  test('Multiple tabs preserve their respective data on create and switch', () async {
    final controller = Get.put(HomePageController());
    await pumpEventQueue();

    // Set data in Tab 1
    controller.controller.text = '{"tab": "first"}';
    expect(controller.selected.data, '{"tab": "first"}');

    // Create Tab 2
    controller.onAdd();
    await pumpEventQueue();
    expect(controller.tabsIndex.length, 2);

    final tab1 = controller.tabsIndex[0];
    final tab2 = controller.tabsIndex[1];

    // Verify Tab 1 retained its data and Tab 2 started fresh
    expect(tab1.data, '{"tab": "first"}');
    expect(controller.controller.text, '');

    // Set data in Tab 2
    controller.controller.text = '{"tab": "second"}';
    expect(tab2.data, '{"tab": "second"}');

    // Switch back to Tab 1
    controller.onSelect(tab1);
    expect(controller.selected.id, tab1.id);
    expect(controller.controller.text, '{"tab": "first"}');
    expect(tab2.data, '{"tab": "second"}');

    // Switch to Tab 2
    controller.onSelect(tab2);
    expect(controller.selected.id, tab2.id);
    expect(controller.controller.text, '{"tab": "second"}');
    expect(tab1.data, '{"tab": "first"}');
  });

  test('Closing a tab deletes its saved data from local storage and memory', () async {
    final controller = Get.put(HomePageController());
    await pumpEventQueue();

    controller.controller.text = '{"tab": "first"}';
    controller.onAdd();
    await pumpEventQueue();
    controller.controller.text = '{"tab": "second"}';

    expect(controller.tabsIndex.length, 2);
    final tab2 = controller.tabsIndex[1];

    // Remove Tab 2
    controller.onRemove(tab2);
    await pumpEventQueue();

    expect(controller.tabsIndex.length, 1);
    expect(controller.tabsIndex.any((t) => t.id == tab2.id), false);
    expect(controller.selected.data, '{"tab": "first"}');

    // Verify local storage is updated
    final prefs = await SharedPreferences.getInstance();
    final savedTabsString = prefs.getString('saved_tabs');
    expect(savedTabsString, isNotNull);
    expect(savedTabsString!.contains('second'), false);
    expect(savedTabsString.contains('first'), true);
  });
}
