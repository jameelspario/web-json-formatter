import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:jsomatter/utils/FormatUtils.dart';

import '../../../domain/tab_model.dart';
import '../../controllers/home_page_controller.dart';
import '../json_formatter/json_text_field_controller.dart';
import '../json_formatter/json_utils.dart';

class JsonBeautifierPage extends StatefulWidget {
  final TabModel? tab;
  final int paneIndex;

  const JsonBeautifierPage({this.tab, this.paneIndex = 0, super.key});

  @override
  State<JsonBeautifierPage> createState() => _JsonBeautifierPageState();
}

class _JsonBeautifierPageState extends State<JsonBeautifierPage> {
  late final HomePageController homeController;
  final _focusNode = FocusNode();
  final format = FormatUtils();

  final ScrollController _editorScrollController = ScrollController();
  final ScrollController _gutterScrollController = ScrollController();
  late final JsonTextFieldController _localController;
  final TextEditingController _findController = TextEditingController();
  final TextEditingController _replaceController = TextEditingController();
  StreamSubscription<void>? _beautifySub;

  TabModel get _currentTab =>
      widget.tab ?? (homeController.selected);

  JsonTextFieldController get _targetController => _localController;

  @override
  void initState() {
    super.initState();
    homeController = Get.find<HomePageController>();

    _localController = JsonTextFieldController()..text = (_currentTab.data ?? "");
    _localController.addListener(_onControllerTextChanged);
    _editorScrollController.addListener(_syncScroll);

    _findController.text = homeController.findQuery.value;
    _replaceController.text = homeController.replaceText.value;

    _findController.addListener(() {
      homeController.findQuery.value = _findController.text;
      _updateSearchAndSelectCurrent(0);
    });

    _replaceController.addListener(() {
      homeController.replaceText.value = _replaceController.text;
    });

    if (widget.paneIndex == 0) {
      _beautifySub = homeController.beautifySignal.stream.listen((_) => _beautify());
    }
  }

  @override
  void didUpdateWidget(covariant JsonBeautifierPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tab?.id != widget.tab?.id) {
      _localController.text = _currentTab.data ?? "";
    }
  }

  // ── Theme helpers ─────────────────────────────────────────────────────────

  bool get _isDark => homeController.isDark.value == 1;

  Color get _bgColor =>
      _isDark ? const Color(0xFF0D1117) : const Color(0xFFF6F8FA);
  Color get _panelColor =>
      _isDark ? const Color(0xFF161B22) : const Color(0xFFFFFFFF);
  Color get _borderColor =>
      _isDark ? const Color(0xFF30363D) : const Color(0xFFD0D7DE);
  Color get _textColor =>
      _isDark ? const Color(0xFFE6EDF3) : const Color(0xFF24292F);
  Color get _hintColor =>
      _isDark ? const Color(0xFF484F58) : const Color(0xFF8C959F);
  Color get _cursorColor =>
      _isDark ? const Color(0xFF00D4AA) : const Color(0xFF0969DA);

  // ── Scroll Sync ───────────────────────────────────────────────────────────

  void _syncScroll() {
    if (_gutterScrollController.hasClients) {
      _gutterScrollController.jumpTo(_editorScrollController.offset);
    }
  }

  // ── Beautify ──────────────────────────────────────────────────────────────

  void _beautify() {
    final input = _targetController.text.trim();
    if (input.isEmpty) {
      return;
    }

    final tokens = format.tokenise(input);
    final result = format.beautify(tokens);

    final oldSelection = _targetController.selection;
    final oldLen = _targetController.text.length;

    _targetController.value = TextEditingValue(
      text: result.raw,
      selection: _mapCursorPosition(oldSelection, oldLen, result.raw.length),
    );
  }

  TextSelection _mapCursorPosition(TextSelection oldSelection, int oldLen, int newLen) {
    if (oldSelection.baseOffset == -1) {
      return TextSelection.collapsed(offset: newLen);
    }
    if (oldLen == 0) return const TextSelection.collapsed(offset: 0);
    final double ratio = oldSelection.baseOffset / oldLen;
    final int newOffset = (ratio * newLen).round().clamp(0, newLen);
    return TextSelection.collapsed(offset: newOffset);
  }

  void _onControllerTextChanged() {
    _currentTab.data = _targetController.text;
    if (widget.paneIndex == 0 && homeController.selected.id == _currentTab.id) {
      if (homeController.controller.text != _targetController.text) {
        homeController.controller.text = _targetController.text;
      }
    }
    _updateSearchAndSelectCurrent(null);
    if (mounted) {
      setState(() {});
    }
  }

  void _updateSearchAndSelectCurrent(int? forcedIndex) {
    final query = homeController.findQuery.value;
    final matches = homeController.findMatches(_targetController.text, query);
    homeController.matchCount.value = matches.length;

    if (matches.isEmpty) {
      homeController.currentMatchIndex.value = 0;
      return;
    }

    int nextIdx;
    if (forcedIndex != null) {
      nextIdx = forcedIndex.clamp(0, matches.length - 1);
    } else {
      final currentPos = _targetController.selection.baseOffset;
      nextIdx = matches.indexWhere((m) => m.start >= currentPos);
      if (nextIdx == -1) nextIdx = 0;
    }

    homeController.currentMatchIndex.value = nextIdx + 1;
    final match = matches[nextIdx];
    _targetController.selection = TextSelection(
      baseOffset: match.start,
      extentOffset: match.end,
    );
  }

  void _nextMatch() {
    final matches = homeController.findMatches(_targetController.text, homeController.findQuery.value);
    if (matches.isEmpty) return;
    int nextIdx = homeController.currentMatchIndex.value % matches.length;
    _updateSearchAndSelectCurrent(nextIdx);
  }

  void _prevMatch() {
    final matches = homeController.findMatches(_targetController.text, homeController.findQuery.value);
    if (matches.isEmpty) return;
    int prevIdx = (homeController.currentMatchIndex.value - 2 + matches.length) % matches.length;
    _updateSearchAndSelectCurrent(prevIdx);
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): homeController.openFindMode,
        const SingleActivator(LogicalKeyboardKey.keyF, meta: true): homeController.openFindMode,
        const SingleActivator(LogicalKeyboardKey.keyH, control: true): homeController.openReplaceMode,
        const SingleActivator(LogicalKeyboardKey.keyH, meta: true): homeController.openReplaceMode,
        const SingleActivator(LogicalKeyboardKey.escape): homeController.closeFindBar,
      },
      child: Obx(() {
        homeController.isDark.value;
        final fontSize = homeController.txtSize.value;
        final isBold = homeController.isBold.value == 1;
        final isItalic = homeController.isItalic.value == 1;
        final isSplit = homeController.isSplitView.value && homeController.splitViewTabs.length >= 2;
        final isFindOpen = homeController.isFindBarOpen.value;

        return Scaffold(
          backgroundColor: _bgColor,
          body: SafeArea(
            child: Column(
              children: [
                if (isSplit) _buildSplitHeader(),
                if (isFindOpen) _buildFindAndReplaceBar(),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: isSplit ? 4 : 16,
                      right: isSplit ? 4 : 16,
                      bottom: 16,
                      top: (isSplit || isFindOpen) ? 4 : 0,
                    ),
                    child: _buildEditorPanel(
                      fontSize: fontSize,
                      isBold: isBold,
                      isItalic: isItalic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildFindAndReplaceBar() {
    final matchCount = homeController.matchCount.value;
    final currentMatchIndex = homeController.currentMatchIndex.value;
    final regexErr = homeController.regexError.value;
    final isReplaceMode = homeController.isReplaceMode.value;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      margin: const EdgeInsets.only(left: 4, right: 4, top: 4, bottom: 2),
      decoration: BoxDecoration(
        color: _panelColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Find Row
          Row(
            children: [
              IconButton(
                icon: Icon(
                  isReplaceMode ? Icons.unfold_less : Icons.unfold_more,
                  size: 16,
                ),
                tooltip: isReplaceMode ? "Hide Replace Bar" : "Show Replace Bar",
                color: _hintColor,
                onPressed: homeController.toggleReplaceMode,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: TextField(
                    controller: _findController,
                    autofocus: true,
                    style: TextStyle(fontSize: 12, color: _textColor),
                    onSubmitted: (_) => _nextMatch(),
                    decoration: InputDecoration(
                      hintText: "Find…",
                      hintStyle: TextStyle(fontSize: 12, color: _hintColor),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(color: _borderColor),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Option Toggle Chips: Match Case, Whole Word, Regex
              _buildOptionChip(
                label: "Aa",
                tooltip: "Match Case",
                isSelected: homeController.isMatchCase.value,
                onTap: () {
                  homeController.isMatchCase.toggle();
                  _updateSearchAndSelectCurrent(0);
                },
              ),
              const SizedBox(width: 4),
              _buildOptionChip(
                label: r"\bW\b",
                tooltip: "Match Whole Word",
                isSelected: homeController.isMatchWholeWord.value,
                onTap: () {
                  homeController.isMatchWholeWord.toggle();
                  _updateSearchAndSelectCurrent(0);
                },
              ),
              const SizedBox(width: 4),
              _buildOptionChip(
                label: ".*",
                tooltip: "Use Regular Expression",
                isSelected: homeController.isUseRegex.value,
                onTap: () {
                  homeController.isUseRegex.toggle();
                  _updateSearchAndSelectCurrent(0);
                },
              ),
              const SizedBox(width: 8),
              // Match count label
              Text(
                regexErr.isNotEmpty
                    ? regexErr
                    : (homeController.findQuery.value.isEmpty
                        ? ""
                        : (matchCount == 0 ? "No results" : "$currentMatchIndex of $matchCount")),
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: regexErr.isNotEmpty
                      ? Colors.redAccent
                      : (matchCount == 0 ? _hintColor : Colors.indigoAccent),
                ),
              ),
              const SizedBox(width: 8),
              // Nav buttons
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 18),
                tooltip: "Previous Match (Shift+Enter)",
                color: _hintColor,
                onPressed: _prevMatch,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                tooltip: "Next Match (Enter)",
                color: _hintColor,
                onPressed: _nextMatch,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 16),
                tooltip: "Close Find Bar (Esc)",
                color: _hintColor,
                onPressed: homeController.closeFindBar,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          if (isReplaceMode) ...[
            const SizedBox(height: 6),
            // Replace Row
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 32,
                    child: TextField(
                      controller: _replaceController,
                      style: TextStyle(fontSize: 12, color: _textColor),
                      onSubmitted: (_) {
                        homeController.replaceInController(_targetController);
                        _updateSearchAndSelectCurrent(null);
                      },
                      decoration: InputDecoration(
                        hintText: "Replace with…",
                        hintStyle: TextStyle(fontSize: 12, color: _hintColor),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(color: _borderColor),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigoAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: const Size(60, 32),
                    textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  onPressed: () {
                    homeController.replaceInController(_targetController);
                    _updateSearchAndSelectCurrent(null);
                  },
                  child: const Text("Replace"),
                ),
                const SizedBox(width: 6),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _textColor,
                    side: BorderSide(color: _borderColor),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: const Size(70, 32),
                    textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  onPressed: () {
                    homeController.replaceAllInController(_targetController);
                    _updateSearchAndSelectCurrent(null);
                  },
                  child: const Text("Replace All"),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOptionChip({
    required String label,
    required String tooltip,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? Colors.indigoAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isSelected ? Colors.indigoAccent : _borderColor,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : _hintColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSplitHeader() {
    final paneLabel = "PANE ${widget.paneIndex + 1}";
    final colors = [
      Colors.indigoAccent,
      Colors.teal,
      Colors.deepOrangeAccent,
      Colors.purpleAccent,
      Colors.blueAccent,
    ];
    final paneColor = colors[widget.paneIndex % colors.length];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      margin: const EdgeInsets.only(left: 4, right: 4, top: 4, bottom: 2),
      decoration: BoxDecoration(
        color: _panelColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: paneColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  paneLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: paneColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _currentTab.id?.toString(),
                  isDense: true,
                  dropdownColor: _panelColor,
                  icon: Icon(Icons.arrow_drop_down, color: _textColor, size: 18),
                  items: homeController.tabsIndex.map((tab) {
                    final isCurrent = tab.id == _currentTab.id;
                    return DropdownMenuItem<String>(
                      value: tab.id.toString(),
                      child: Text(
                        tab.name.toString().startsWith("Tab") ? tab.name.toString() : "Tab ${tab.name}",
                        style: TextStyle(
                          fontSize: 12,
                          color: isCurrent ? paneColor : _textColor,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (newTabId) {
                    if (newTabId == null) return;
                    final targetTab = homeController.tabsIndex
                        .firstWhereOrNull((t) => t.id.toString() == newTabId);
                    if (targetTab == null) return;

                    homeController.replaceSplitPaneTab(widget.paneIndex, targetTab);
                  },
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.add_rounded, size: 16),
                tooltip: "Add New Tab in Split",
                color: _hintColor,
                onPressed: () => homeController.addNewTabToSplit(targetIndex: widget.paneIndex + 1),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              if (widget.paneIndex > 0)
                IconButton(
                  icon: const Icon(Icons.west_rounded, size: 14),
                  tooltip: "Move Left",
                  color: _hintColor,
                  onPressed: () => homeController.moveSplitPaneLeft(widget.paneIndex),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              if (widget.paneIndex < homeController.splitViewTabs.length - 1) ...[
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.east_rounded, size: 14),
                  tooltip: "Move Right",
                  color: _hintColor,
                  onPressed: () => homeController.moveSplitPaneRight(widget.paneIndex),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 16),
                tooltip: "Close Split Pane",
                color: _hintColor,
                onPressed: () => homeController.removePaneFromSplit(widget.paneIndex),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditorPanel({
    required double fontSize,
    required bool isBold,
    required bool isItalic,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _panelColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildGutter(fontSize),
                Expanded(
                  child: _buildEditor(
                    fontSize: fontSize,
                    isBold: isBold,
                    isItalic: isItalic,
                  ),
                ),
              ],
            ),
          ),
          _buildErrorBanner(),
        ],
      ),
    );
  }

  // ── Synced Line Numbers Gutter ────────────────────────────────────────────

  Widget _buildGutter(double fontSize) {
    final text = _targetController.text;
    final lineCount = '\n'.allMatches(text).length + 1;

    return Container(
      width: 48,
      decoration: BoxDecoration(
        color: _isDark ? const Color(0xFF0D1117) : const Color(0xFFF6F8FA),
        border: Border(
          right: BorderSide(
            color: _borderColor,
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        controller: _gutterScrollController,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(lineCount, (index) {
            return Container(
              height: fontSize * 1.6,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: fontSize,
                  color: _hintColor,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ── The editor ────────────────────────────────────────────────────────────

  Widget _buildEditor({
    required double fontSize,
    required bool isBold,
    required bool isItalic,
  }) {
    final editorStyle = TextStyle(
      fontSize: fontSize,
      height: 1.6,
      fontFamily: 'monospace',
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
    );

    return TextField(
      controller: _targetController,
      focusNode: _focusNode,
      scrollController: _editorScrollController,
      maxLines: null,
      expands: true,
      style: editorStyle.copyWith(color: _textColor),
      cursorColor: _cursorColor,
      decoration: InputDecoration(
        border: InputBorder.none,
        contentPadding: const EdgeInsets.all(14),
        hintText: 'Paste your JSON here…',
        hintStyle: TextStyle(color: _hintColor),
      ),
    );
  }

  // ── Error warning banner ──────────────────────────────────────────────────

  Widget _buildErrorBanner() {
    final text = _targetController.text;
    final errorMsg = text.isEmpty ? "" : (JsonUtils.getJsonParsingError(text) ?? "");
    final isValid = text.isEmpty || errorMsg.isEmpty;

    if (isValid || errorMsg.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _isDark ? const Color(0xFF3B1E1E) : const Color(0xFFFFECEC),
        border: Border(
          top: BorderSide(
            color: _isDark ? const Color(0xFF8A3838) : const Color(0xFFF5C2C2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: _isDark ? const Color(0xFFFF6B6B) : const Color(0xFFC53030),
            size: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              errorMsg,
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: _isDark ? const Color(0xFFFFD8D8) : const Color(0xFF9B2C2C),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _localController.removeListener(_onControllerTextChanged);
    _localController.dispose();
    _editorScrollController.removeListener(_syncScroll);
    _editorScrollController.dispose();
    _gutterScrollController.dispose();
    _beautifySub?.cancel();
    _focusNode.dispose();
    super.dispose();
  }
}
