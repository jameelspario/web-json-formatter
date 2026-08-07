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

  test('Closing a tab deletes its active session, but saved tab remains in savedTabsList', () async {
    final controller = Get.put(HomePageController());
    await pumpEventQueue();

    controller.controller.text = '{"tab": "persistent"}';
    final activeTab = controller.selected;

    // Save tab to permanent Saved Tabs List
    controller.saveCurrentTabToSavedList(customName: 'MyPersistentTab');
    expect(controller.savedTabsList.length, 1);
    expect(controller.savedTabsList.first.name, 'MyPersistentTab');

    // Close the active tab session
    controller.onRemove(activeTab);
    await pumpEventQueue();

    // Closed active session is gone from top bar
    expect(controller.tabsIndex.any((t) => t.id == activeTab.id), false);

    // BUT tab remains saved in savedTabsList!
    expect(controller.savedTabsList.length, 1);
    expect(controller.savedTabsList.first.name, 'MyPersistentTab');
    expect(controller.savedTabsList.first.data, '{"tab": "persistent"}');

    // Re-load the closed tab back to active editor tabs from saved list
    final savedTab = controller.savedTabsList.first;
    controller.loadSavedTabToActive(savedTab);
    await pumpEventQueue();

    expect(controller.selected.name, 'MyPersistentTab');
    expect(controller.controller.text, '{"tab": "persistent"}');
  });

  test('Edit and Delete saved tabs from Saved Tabs list', () async {
    final controller = Get.put(HomePageController());
    await pumpEventQueue();

    controller.controller.text = '{"foo": "bar"}';
    controller.saveCurrentTabToSavedList(customName: 'OriginalName');

    final savedTab = controller.savedTabsList.first;

    // Edit saved tab
    controller.editSavedTabInList(savedTab, newName: 'EditedName', newData: '{"foo": "updated"}');

    expect(controller.savedTabsList.first.name, 'EditedName');
    expect(controller.savedTabsList.first.data, '{"foo": "updated"}');
    expect(controller.controller.text, '{"foo": "updated"}');

    // Delete saved tab
    controller.deleteSavedTabFromList(savedTab.id);
    expect(controller.savedTabsList.isEmpty, true);
  });
}
