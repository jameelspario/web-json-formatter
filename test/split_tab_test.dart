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

  test('Split View toggles on and off correctly', () async {
    final controller = Get.put(HomePageController());
    await pumpEventQueue();

    expect(controller.isSplitView.value, false);

    // Toggle Split View ON
    controller.toggleSplitView();
    await pumpEventQueue();

    expect(controller.isSplitView.value, true);
    expect(controller.splitViewTabs.length, 2);

    // Close all splits
    controller.closeAllSplits();
    await pumpEventQueue();

    expect(controller.isSplitView.value, false);
    expect(controller.splitViewTabs.isEmpty, true);
  });

  test('Supports N-Way split view with 3+ tabs side-by-side', () async {
    final controller = Get.put(HomePageController());
    await pumpEventQueue();

    controller.openDefaultSplit();
    await pumpEventQueue();
    expect(controller.splitViewTabs.length, 2);

    // Add 3rd tab to split
    controller.addNewTabToSplit();
    await pumpEventQueue();
    expect(controller.splitViewTabs.length, 3);
    expect(controller.isSplitView.value, true);

    // Add 4th tab to split
    controller.addNewTabToSplit();
    await pumpEventQueue();
    expect(controller.splitViewTabs.length, 4);
  });

  test('Splitting tabs left and right positions tabs correctly', () async {
    final controller = Get.put(HomePageController());
    await pumpEventQueue();

    final tab1 = controller.selected;
    controller.onAdd();
    final tab2 = controller.selected;

    // Split Tab 2 to Left
    controller.splitTabLeft(tab2);
    await pumpEventQueue();
    expect(controller.splitViewTabs.first.id, tab2.id);

    // Split Tab 1 to Right
    controller.splitTabRight(tab1);
    await pumpEventQueue();
    expect(controller.splitViewTabs.last.id, tab1.id);
  });

  test('Closing split panes until 1 remains automatically returns to normal single tab view', () async {
    final controller = Get.put(HomePageController());
    await pumpEventQueue();

    controller.openDefaultSplit();
    controller.addNewTabToSplit();
    await pumpEventQueue();
    expect(controller.splitViewTabs.length, 3);

    // Remove pane 2
    controller.removePaneFromSplit(2);
    await pumpEventQueue();
    expect(controller.splitViewTabs.length, 2);
    expect(controller.isSplitView.value, true);

    // Remove pane 1 -> only 1 split tab left -> returns to normal mode!
    controller.removePaneFromSplit(1);
    await pumpEventQueue();
    expect(controller.isSplitView.value, false);
    expect(controller.splitViewTabs.isEmpty, true);
  });
}
