import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/home_page_controller.dart';
import 'json_utils.dart';

class JsonTextFieldController extends TextEditingController {
  JsonTextFieldController();

  /// Format the JSON text in the controller. Use [sortJson] to sort the JSON keys.
  formatJson({required bool sortJson}) {
    // if (JsonUtils.isValidJson(text)) {
      JsonUtils.formatTextFieldJson(sortJson: sortJson, controller: this);
    // }
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final spans = <TextSpan>[];
    final String src = text;
    int i = 0;

    bool isDark = false;
    HomePageController? homeController;
    try {
      if (Get.isRegistered<HomePageController>()) {
        homeController = Get.find<HomePageController>();
        isDark = homeController.isDark.value == 1;
      }
    } catch (_) {}

    // Choose premium colors
    final colBrace = isDark ? const Color(0xFFFFD166) : const Color(0xFF57606A);
    final colKey = isDark ? const Color(0xFF79C0FF) : const Color(0xFF0550AE);
    final colString = isDark ? const Color(0xFFFF7B72) : const Color(0xFFCF222E);
    final colNumber = isDark ? const Color(0xFF7EE787) : const Color(0xFF116329);
    final colBool = isDark ? const Color(0xFFFFAB70) : const Color(0xFF953800);
    final colNormal = isDark ? const Color(0xFFC9D1D9) : const Color(0xFF24292F);

    bool peekIsColon(int index) {
      int j = index;
      while (j < src.length) {
        final c = src[j];
        if (c == ' ' || c == '\t' || c == '\r' || c == '\n') {
          j++;
          continue;
        }
        return c == ':';
      }
      return false;
    }

    while (i < src.length) {
      final ch = src[i];

      // Braces / brackets
      if (ch == '{' || ch == '}' || ch == '[' || ch == ']') {
        spans.add(TextSpan(text: ch, style: (style ?? const TextStyle()).copyWith(color: colBrace)));
        i++;
        continue;
      }

      // Colons / commas
      if (ch == ':' || ch == ',') {
        spans.add(TextSpan(text: ch, style: (style ?? const TextStyle()).copyWith(color: colNormal)));
        i++;
        continue;
      }

      // Strings (Keys or Values)
      if (ch == '"') {
        final start = i;
        i++; // skip open quote
        bool escaped = false;
        while (i < src.length) {
          final c = src[i];
          if (escaped) {
            escaped = false;
          } else if (c == '\\') {
            escaped = true;
          } else if (c == '"') {
            i++; // consume close quote
            break;
          }
          i++;
        }
        final stringVal = src.substring(start, i);
        final isKey = peekIsColon(i);
        final color = isKey ? colKey : colString;
        spans.add(TextSpan(text: stringVal, style: (style ?? const TextStyle()).copyWith(color: color)));
        continue;
      }

      // Numbers
      if (ch == '-' || (ch.codeUnitAt(0) >= 48 && ch.codeUnitAt(0) <= 57)) {
        final start = i;
        i++;
        while (i < src.length) {
          final c = src[i];
          if ((c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57) ||
              c == '.' ||
              c == 'e' ||
              c == 'E' ||
              c == '+' ||
              c == '-') {
            i++;
          } else {
            break;
          }
        }
        final numVal = src.substring(start, i);
        spans.add(TextSpan(text: numVal, style: (style ?? const TextStyle()).copyWith(color: colNumber)));
        continue;
      }

      // Booleans / Null
      if ((ch.codeUnitAt(0) >= 65 && ch.codeUnitAt(0) <= 90) || // A-Z
          (ch.codeUnitAt(0) >= 97 && ch.codeUnitAt(0) <= 122) || // a-z
          ch == '_') {
        final start = i;
        while (i < src.length) {
          final c = src[i];
          final code = c.codeUnitAt(0);
          if ((code >= 65 && code <= 90) ||
              (code >= 97 && code <= 122) ||
              c == '_') {
            i++;
          } else {
            break;
          }
        }
        final word = src.substring(start, i);
        final isKeyword = (word == 'true' || word == 'false' || word == 'null');
        final color = isKeyword ? colBool : colNormal;
        spans.add(TextSpan(
          text: word,
          style: (style ?? const TextStyle()).copyWith(
            color: color,
            fontWeight: isKeyword ? FontWeight.bold : FontWeight.normal,
          ),
        ));
        continue;
      }

      // Normal characters / whitespace
      final start = i;
      while (i < src.length) {
        final c = src[i];
        if (c == '{' || c == '}' || c == '[' || c == ']' || c == ':' || c == ',' || c == '"' ||
            c == '-' || (c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57) ||
            (c.codeUnitAt(0) >= 65 && c.codeUnitAt(0) <= 90) ||
            (c.codeUnitAt(0) >= 97 && c.codeUnitAt(0) <= 122) ||
            c == '_') {
          break;
        }
        i++;
      }
      final normalVal = src.substring(start, i);
      spans.add(TextSpan(text: normalVal, style: (style ?? const TextStyle()).copyWith(color: colNormal)));
    }

    // Apply Search Highlights if Find bar is active
    if (homeController != null &&
        homeController.isFindBarOpen.value &&
        homeController.findQuery.value.isNotEmpty) {
      final matches = homeController.findMatches(src, homeController.findQuery.value);
      if (matches.isNotEmpty) {
        final activeIndex = homeController.currentMatchIndex.value - 1;
        return _applySearchHighlights(spans, matches, activeIndex, style, isDark);
      }
    }

    return TextSpan(children: spans);
  }

  TextSpan _applySearchHighlights(
    List<TextSpan> baseSpans,
    List<Match> matches,
    int activeMatchIndex,
    TextStyle? defaultStyle,
    bool isDark,
  ) {
    final finalSpans = <TextSpan>[];
    int currentOffset = 0;

    final activeColor = isDark ? const Color(0xFFE65100) : const Color(0xFFFF9800);
    final matchColor = isDark ? const Color(0xFF5A4D00) : const Color(0xFFFFF176);
    final activeTextColor = Colors.white;

    for (final span in baseSpans) {
      final spanText = span.text ?? "";
      if (spanText.isEmpty) continue;
      final spanEnd = currentOffset + spanText.length;

      int localStart = 0;
      while (localStart < spanText.length) {
        final absPos = currentOffset + localStart;

        int matchIdx = -1;
        for (int m = 0; m < matches.length; m++) {
          if (absPos >= matches[m].start && absPos < matches[m].end) {
            matchIdx = m;
            break;
          }
        }

        if (matchIdx != -1) {
          final m = matches[matchIdx];
          final absChunkEnd = min(spanEnd, m.end);
          final localChunkEnd = absChunkEnd - currentOffset;
          final chunkText = spanText.substring(localStart, localChunkEnd);

          final isActive = (matchIdx == activeMatchIndex);
          final highlightStyle = (span.style ?? defaultStyle ?? const TextStyle()).copyWith(
            backgroundColor: isActive ? activeColor : matchColor,
            color: isActive ? activeTextColor : (span.style?.color ?? defaultStyle?.color),
            fontWeight: isActive ? FontWeight.bold : span.style?.fontWeight,
          );

          finalSpans.add(TextSpan(text: chunkText, style: highlightStyle));
          localStart = localChunkEnd;
        } else {
          int absNextMatch = spanEnd;
          for (final m in matches) {
            if (m.start > absPos && m.start < absNextMatch) {
              absNextMatch = m.start;
            }
          }
          final localChunkEnd = absNextMatch - currentOffset;
          final chunkText = spanText.substring(localStart, localChunkEnd);

          finalSpans.add(TextSpan(text: chunkText, style: span.style));
          localStart = localChunkEnd;
        }
      }

      currentOffset = spanEnd;
    }

    return TextSpan(children: finalSpans);
  }
}