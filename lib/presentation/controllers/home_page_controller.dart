import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/tab_model.dart';
import '../../domain/cloud_json_model.dart';
import '../../utils/utils.dart';
import '../../utils/cloud_storage_service.dart';
import '../view/json_formatter/json_text_field_controller.dart';
import '../view/json_formatter/json_utils.dart';
import '../widgets/show_toast_dialog.dart';
import '../widgets/profile_dialog.dart';
import 'logger_controller.dart';

class HomePageController extends GetxController {
  final LoggerController logger = Get.find();

  int count = 0;
  final _selected = TabModel().obs;
  RxList<TabModel> tabsIndex = <TabModel>[].obs;

  TabModel get selected => _selected.value;

  select(TabModel val) {
    _selected(val);
  }

  int state = 0;

  final utils = Utils();

  // final TextEditingController txtController = TextEditingController();
  final JsonTextFieldController controller = JsonTextFieldController();

  var txtSize = 16.0.obs;
  var isBold = 0.obs;
  var isItalic = 0.obs;
  var isDark = 0.obs;

  // Cloud Save & Account Variables
  var currentUserEmail = RxnString();
  var savedJsons = <CloudJson>[].obs;
  var cloudSyncMode = 'Local'.obs;

  // Signal so JsonBeautifierPage can subscribe and run beautify
  final beautifySignal = StreamController<void>.broadcast();

  bool _isUpdatingController = false;

  static const List<String> _randomKeywords = [
    "Alpha", "Beta", "Gamma", "Delta", "Nexus", "Quantum", "Vortex", "Pixel",
    "Matrix", "Cipher", "Apex", "Orbit", "Prism", "Flux", "Echo", "Spark",
    "Pulse", "Logic", "Cyber", "Nova", "Zenith", "Core", "Node", "Vector",
    "Aura", "Starlight", "Hyper", "Titan", "Beacon", "Sol", "Omega", "Helix"
  ];

  String _generateRandomKeyword() {
    final random = Random();
    final word = _randomKeywords[random.nextInt(_randomKeywords.length)];
    final num = random.nextInt(900) + 100;
    return "$word-$num";
  }

  onSelect(TabModel m) {
    if (selected.id == m.id) return;
    saveOldSelection();
    select(m);
    assignSelection(m);
    _saveTabsToLocal();
  }

  onRemove(TabModel m) {
    final int removeIndex = tabsIndex.indexWhere((it) => it.id == m.id);
    if (removeIndex == -1) return;

    final bool removingSelected = (selected.id == m.id);
    tabsIndex.removeAt(removeIndex);

    if (tabsIndex.isEmpty) {
      onAdd();
    } else if (removingSelected) {
      final int nextIndex =
          removeIndex < tabsIndex.length ? removeIndex : tabsIndex.length - 1;
      final nextTab = tabsIndex[nextIndex];
      select(nextTab);
      assignSelection(nextTab);
      _saveTabsToLocal();
    } else {
      _saveTabsToLocal();
    }
  }

  onAdd() {
    saveOldSelection();
    final val = tabinit();
    tabsIndex.add(val);
    select(val);
    resetSelection();
    _saveTabsToLocal();
  }

  void onReorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item =
        tabsIndex.removeAt(oldIndex); // Remove the item from the old position
    tabsIndex.insert(newIndex, item);
    _saveTabsToLocal();
  }

  saveOldSelection() {
    if (selected.id != null) {
      selected.data = controller.text;
      selected.txtSize = txtSize.value;
      selected.isBold = isBold.value;
      selected.isItalic = isItalic.value;
      selected.state = state;
    }
  }

  resetSelection() {
    _isUpdatingController = true;
    controller.text = "";
    txtSize.value = 16.0;
    isBold.value = 0;
    isItalic.value = 0;
    state = 0;
    _isUpdatingController = false;
    _updateJsonValidationAndCursor();
  }

  assignSelection(TabModel m) {
    _isUpdatingController = true;
    controller.text = m.data ?? "";
    txtSize.value = (m.txtSize as num?)?.toDouble() ?? 16.0;
    isBold.value = m.isBold ?? 0;
    isItalic.value = m.isItalic ?? 0;
    state = m.state ?? 0;
    _isUpdatingController = false;
    _updateJsonValidationAndCursor();
  }

  TabModel tabinit() {
    count++;
    final String keyword = _generateRandomKeyword();
    final model = TabModel(
      id: "${DateTime.now().millisecondsSinceEpoch}_$count",
      name: keyword,
      data: "",
      txtSize: 16.0,
      state: 0,
      isBold: 0,
      isItalic: 0,
    );
    return model;
  }

  @override
  void onInit() {
    super.onInit();
    _loadTheme();
    _loadTabsFromLocal();
    controller.addListener(_onTextChanged);
    _initCloudUser();
  }

  _initCloudUser() async {
    if (CloudStorageManager.firebaseInitialized) {
      cloudSyncMode.value = 'Firebase';
    } else {
      cloudSyncMode.value = 'Local';
    }
    currentUserEmail.value = CloudStorageManager.service.getCurrentUserEmail();
    if (currentUserEmail.value != null) {
      await refreshSavedJsons();
    }
  }

  Future<void> refreshSavedJsons() async {
    if (currentUserEmail.value != null) {
      savedJsons.value = await CloudStorageManager.service.fetchSavedJsons();
    }
  }

  onProfile() {
    Get.dialog(const ProfileDialog());
  }

  Future<bool> loginCloud(String email, String password) async {
    final success = await CloudStorageManager.service.login(email, password);
    if (success) {
      currentUserEmail.value = email;
      await refreshSavedJsons();
      ShowToastDialog.showToast("Logged in successfully");
    }
    return success;
  }

  Future<bool> signUpCloud(String email, String password) async {
    final success = await CloudStorageManager.service.signUp(email, password);
    if (success) {
      currentUserEmail.value = email;
      await refreshSavedJsons();
      ShowToastDialog.showToast("Account created successfully");
    }
    return success;
  }

  Future<void> logoutCloud() async {
    await CloudStorageManager.service.logout();
    currentUserEmail.value = null;
    savedJsons.clear();
    ShowToastDialog.showToast("Logged out");
  }

  Future<bool> saveCurrentJsonToCloud(String name) async {
    if (currentUserEmail.value == null) {
      ShowToastDialog.showToast("Please log in first");
      return false;
    }
    final content = controller.text;
    if (content.isEmpty) {
      ShowToastDialog.showToast("JSON is empty");
      return false;
    }

    final success = await CloudStorageManager.service.saveJson(name, content);
    if (success) {
      await refreshSavedJsons();
      ShowToastDialog.showToast("JSON saved to cloud");
      return true;
    } else {
      ShowToastDialog.showToast("Save failed. Limit reached (max 5 slots)");
      return false;
    }
  }

  Future<void> deleteJsonFromCloud(String id) async {
    final success = await CloudStorageManager.service.deleteJson(id);
    if (success) {
      await refreshSavedJsons();
      ShowToastDialog.showToast("Document deleted");
    } else {
      ShowToastDialog.showToast("Delete failed");
    }
  }

  void loadCloudJson(String content) {
    controller.text = content;
    Get.back();
    ShowToastDialog.showToast("Loaded JSON from cloud");
  }

  void toggleCloudMode(String mode) async {
    if (mode == 'Firebase' && !CloudStorageManager.firebaseInitialized) {
      ShowToastDialog.showToast("Firebase is not configured on this device");
      return;
    }
    await logoutCloud();
    if (mode == 'Firebase') {
      CloudStorageManager.service = FirebaseCloudStorageService();
      cloudSyncMode.value = 'Firebase';
    } else {
      CloudStorageManager.service = SimulatedCloudStorageService();
      cloudSyncMode.value = 'Local';
    }
    _initCloudUser();
    ShowToastDialog.showToast("Switched sync mode to $mode");
  }

  _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    isDark.value = prefs.getInt('isDark') ?? 0;
  }

  Future<void> _saveTabsToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = tabsIndex.map((tab) => tab.toJson()).toList();
      final jsonString = jsonEncode(list);
      await prefs.setString('saved_tabs', jsonString);
      
      if (selected.id != null) {
        await prefs.setString('selected_tab_id', selected.id.toString());
      }
      await prefs.setInt('tab_count', count);
    } catch (e) {
      print("Error saving tabs: $e");
    }
  }

  Future<void> _loadTabsFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('saved_tabs');
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonString);
        final loadedTabs = decoded
            .map((item) => TabModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();
        if (loadedTabs.isNotEmpty) {
          tabsIndex.clear();
          tabsIndex.addAll(loadedTabs);
          
          count = prefs.getInt('tab_count') ?? loadedTabs.length;
          
          final selectedTabIdStr = prefs.getString('selected_tab_id');
          TabModel? selectTab;
          if (selectedTabIdStr != null) {
            for (var tab in tabsIndex) {
              if (tab.id.toString() == selectedTabIdStr) {
                selectTab = tab;
                break;
              }
            }
          }
          selectTab ??= tabsIndex.first;
          
          select(selectTab);
          assignSelection(selectTab);
          return;
        }
      }
    } catch (e) {
      print("Error loading tabs: $e");
    }
    
    // Fallback if no tabs loaded
    onAdd();
  }

  int lineNumber = 1;
  var columnNumber = 1.obs;
  var isValidJson = true.obs;
  var jsonErrorMsg = "".obs;

  _onTextChanged() {
    if (_isUpdatingController) return;

    final text = controller.text;
    if (selected.id != null) {
      selected.data = text;
      _saveTabsToLocal();
    }

    _updateJsonValidationAndCursor();
  }

  void _updateJsonValidationAndCursor() {
    final text = controller.text;

    // Validate JSON in the background
    if (text.isEmpty) {
      isValidJson.value = true;
      jsonErrorMsg.value = "";
    } else {
      final error = JsonUtils.getJsonParsingError(text);
      if (error == null) {
        isValidJson.value = true;
        jsonErrorMsg.value = "";
      } else {
        isValidJson.value = false;
        jsonErrorMsg.value = error;
      }
    }

    final cursorPosition = controller.selection.baseOffset;

    if (cursorPosition == -1) {
      lineNumber = 1;
      columnNumber.value = 1;
      return;
    }

    // Split the text into lines
    final lines = text.split('\n');

    // Determine the line number
    int line = 0;
    int charsCount = 0;

    for (int i = 0; i < lines.length; i++) {
      final lineLength = lines[i].length;

      if (cursorPosition <= charsCount + lineLength) {
        line = i + 1;
        break;
      }

      charsCount += lineLength + 1; // Adding 1 for the newline character
    }

    // Determine the column number
    final column = cursorPosition - charsCount + 1;

    lineNumber = line == 0 ? 1 : line;
    columnNumber.value = column < 1 ? 1 : column;
  }

  onSizeChange(double size) {
    print("-------$size");
    txtSize.value = size;
    selected.txtSize = size;
    _saveTabsToLocal();
  }

  onBold() {
    isBold.value = isBold.value == 1 ? 0 : 1;
    selected.isBold = isBold.value;
    _saveTabsToLocal();
  }

  onItalic() {
    isItalic.value = isItalic.value == 1 ? 0 : 1;
    selected.isItalic = isItalic.value;
    _saveTabsToLocal();
  }

  onDark() async {
    isDark.value = isDark.value == 1 ? 0 : 1;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('isDark', isDark.value);
  }

  onOptionMenu(String val) async {
    print(val);
    if (val == "Paste") {
      final data = await utils.pasteFromClipboard();
      controller.text = controller.text + (data ?? "");
    } else if (val == "Copy") {
      final data = controller.text;
      if (data.isNotEmpty) {
        utils.copytoclipboard(data);
      }
    } else if (val == "Format") {
      print("---beautify signal----------");
      beautifySignal.add(null);
      state = 1;
      selected.state = 1;
      _saveTabsToLocal();
    } else if (val == "Remove white space") {
      compactJson();
      state = 2;
      selected.state = 2;
      _saveTabsToLocal();
    } else if (val == "Clear") {
      controller.text = "";
    } else if (val == "Load JSON data") {}
  }

  onFormat() {
    final str = controller.text;
    if (str.isEmpty) {
      return;
    }

    try {
      controller.formatJson(sortJson: false);
      state = 1;
      selected.state = 1;
      _saveTabsToLocal();
    } catch (e) {
      print("-- $e");
      final jsonified = Utils.jsonifyString(str);
      controller.text = jsonified;

      try {
        controller.formatJson(sortJson: false);
        state = 1;
        selected.state = 1;
        _saveTabsToLocal();
      } catch (e2) {
        print("-- second format attempt failed: $e2");
        if (!JsonUtils.isValidJson(controller.text)) {
          // If still invalid, try one last repair manually to show user
          final repaired = JsonUtils.repairJson(controller.text);
          if (JsonUtils.isValidJson(repaired)) {
            controller.text = repaired;
            controller.formatJson(sortJson: false);
            state = 1;
            selected.state = 1;
            _saveTabsToLocal();
          } else {
            logger.logger("${JsonUtils.getJsonParsingError(controller.text)}"
                .replaceAll("FormatException: SyntaxError:", ""));
            ShowToastDialog.showToast("Invalid JSON");
          }
        }
      }
    }
  }

  compactJson() {
    final str = controller.text;
    String compactJson = Utils.compactJson(str);
    controller.text = compactJson;
  }

  @override
  void onClose() {
    beautifySignal.close();
    super.onClose();
  }
}
