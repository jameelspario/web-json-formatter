import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../utils/extensions.dart';
import '../../controllers/home_page_controller.dart';
import '../editor/EditorPannel.dart';
import 'option_menu.dart';

import 'package:resizable_widget/resizable_widget.dart';

class ViewerPage extends StatelessWidget {
  ViewerPage({super.key});

  final HomePageController homeController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OptionMenu(
              callback: homeController.onOptionMenu,
              onSizeChange: homeController.onSizeChange,
              isBold: homeController.isBold,
              isItalic: homeController.isItalic,
              isDark: homeController.isDark,
              onBold: homeController.onBold,
              onItalic: homeController.onItalic,
              onDark: homeController.onDark,
              onProfile: homeController.onProfile,
            ),
            4.0.spaceY,
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Obx(() {
                  final splitTabs = homeController.splitViewTabs;
                  final isSplit = homeController.isSplitView.value && splitTabs.length >= 2;

                  if (!isSplit) {
                    return JsonBeautifierPage(
                      key: ValueKey(homeController.selected.id),
                      tab: homeController.selected,
                      paneIndex: 0,
                    );
                  }

                  final double equalRatio = 1.0 / splitTabs.length;
                  final percentages = List.generate(splitTabs.length, (_) => equalRatio);

                  return ResizableWidget(
                    key: ValueKey("split_${splitTabs.map((t) => t.id).join('_')}"),
                    isHorizontalSeparator: false,
                    isDisabledSmartHide: true,
                    separatorColor: homeController.isDark.value == 1
                        ? const Color(0xFF30363D)
                        : Colors.grey.shade400,
                    separatorSize: 4,
                    percentages: percentages,
                    children: List.generate(splitTabs.length, (index) {
                      final t = splitTabs[index];
                      return JsonBeautifierPage(
                        key: ValueKey("pane_${index}_${t.id}"),
                        tab: t,
                        paneIndex: index,
                      );
                    }),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
