import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../../utils/extensions.dart';
import '../../../domain/tab_model.dart';
import '../../controllers/home_page_controller.dart';

typedef BuilderItem = Widget Function(dynamic it, int index);

class TabHome extends StatelessWidget {
  const TabHome(
      {this.items = const [],
      this.selected,
      this.onSelect,
      this.onRemove,
      this.onAdd,
      required this.onReorder,
      super.key});

  final List items;
  final Function(TabModel m)? onSelect;
  final Function(TabModel m)? onRemove;
  final VoidCallback? onAdd;
  final ReorderCallback onReorder;
  final TabModel? selected;

  @override
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SizedBox(
                height: 20,
                child: DraggableTabs(
                  items: items,
                  onSelect: onSelect,
                  onRemove: onRemove,
                  onReorder: onReorder,
                  builder: (it, i) {
                    return ItemTab(
                      item: it,
                      selected: selected,
                      callback: () {
                        final homeController = Get.find<HomePageController>();
                        if (homeController.isSplitView.value &&
                            homeController.selected.id == it.id) {
                          // Already selected primary, no-op
                        } else {
                          onSelect?.call(it);
                        }
                      },
                      onRemove: () => onRemove?.call(it),
                    );
                  },
                )),
          ),
          Obx(() {
            final controller = Get.find<HomePageController>();
            final isDark = controller.isDark.value == 1;
            final isSplit = controller.isSplitView.value;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: onAdd,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Icon(
                      Icons.add,
                      size: 18,
                      color: isDark ? const Color(0xFF8B949E) : Colors.black54,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Tooltip(
                  message: isSplit ? "Close Split View" : "Split View (Side-by-Side)",
                  child: InkWell(
                    onTap: controller.toggleSplitView,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: isSplit
                            ? (isDark ? Colors.teal.shade700 : Colors.teal)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.splitscreen_rounded,
                        size: 16,
                        color: isSplit
                            ? Colors.white
                            : (isDark ? const Color(0xFF8B949E) : Colors.black54),
                      ),
                    ),
                  ),
                ),
              ],
            );
          })
        ],
      ),
    );
  }
}

class DraggableTabs extends StatefulWidget {
  const DraggableTabs(
      {this.items = const [],
      this.selected,
      this.onSelect,
      this.onRemove,
      required this.onReorder,
      required this.builder,
      super.key});

  final List items;
  final TabModel? selected;
  final Function(TabModel m)? onSelect;
  final Function(TabModel m)? onRemove;
  final ReorderCallback onReorder;
  final BuilderItem builder;

  @override
  State<DraggableTabs> createState() => _DraggableTabsState();
}

class _DraggableTabsState extends State<DraggableTabs> {
  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      proxyDecorator: (child, index, anim) {
        return Material(
          color: Colors.transparent,
          child: Opacity(opacity: 1.0, child: child),
        );
      },
      buildDefaultDragHandles: false,
      scrollDirection: Axis.horizontal,
      itemCount: widget.items.length,
      onReorder: widget.onReorder,
      itemBuilder: (context, i) => ReorderableDragStartListener(
        key: ValueKey(i),
        index: i,
        child: widget.builder(widget.items[i], i),
      ),
    );
  }
}

class ItemTab extends StatelessWidget {
  const ItemTab(
      {required this.item,
      this.selected,
      this.callback,
      this.onRemove,
      super.key});

  final TabModel item;
  final TabModel? selected;
  final VoidCallback? callback;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final homeController = Get.find<HomePageController>();
    return Obx(() {
      final isDark = homeController.isDark.value == 1;
      final isSelected = selected?.id == item.id;
      final isSplit = homeController.isSplitView.value && homeController.splitViewTabs.length >= 2;
      final splitIndex = isSplit
          ? homeController.splitViewTabs.indexWhere((t) => t.id == item.id)
          : -1;
      final isInSplit = splitIndex != -1;

      final colors = [
        Colors.indigoAccent,
        Colors.teal.shade600,
        Colors.deepOrangeAccent.shade400,
        Colors.purpleAccent.shade400,
        Colors.blueAccent,
      ];

      Color? tabBgColor;
      if (isInSplit) {
        tabBgColor = colors[splitIndex % colors.length];
      } else if (isSelected) {
        tabBgColor = Colors.indigoAccent;
      }

      final Color unselectedTextColor =
          isDark ? const Color(0xFFE6EDF3) : Colors.black87;
      final Color unselectedIconColor =
          isDark ? const Color(0xFF8B949E) : Colors.black38;
      final Color borderColor =
          isDark ? const Color(0xFF30363D) : Colors.black45;

      return Padding(
        padding: const EdgeInsets.only(right: 2),
        child: InkWell(
          hoverColor: Colors.indigoAccent.shade100,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
          onTap: () {
            callback?.call();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: tabBgColor,
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(5.0), topRight: Radius.circular(5)),
              border: Border(right: BorderSide(width: 1, color: borderColor)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SvgPicture.asset("assets/svg/json.svg",
                    width: 18,
                    colorFilter: ColorFilter.mode(
                      (isSelected || isInSplit) ? Colors.white : unselectedIconColor,
                      BlendMode.srcIn,
                    )),
                2.0.spaceX,
                Text(
                  item.name.toString().startsWith("Tab") ? item.name.toString() : "Tab ${item.name}",
                  style: TextStyle(
                      color: (isSelected || isInSplit) ? Colors.white : unselectedTextColor,
                      fontSize: 12),
                ),
                if (isInSplit) ...[
                  2.0.spaceX,
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text("P${splitIndex + 1}",
                        style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
                if (isSelected || isInSplit) ...[
                  2.0.spaceX,
                  Tooltip(
                    message: "Save tab",
                    child: InkWell(
                      onTap: () => homeController.saveTabToSavedList(item),
                      child: const Padding(
                        padding: EdgeInsets.all(2.0),
                        child: Icon(
                          Icons.bookmark_add_outlined,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Tooltip(
                    message: "Split Left",
                    child: InkWell(
                      onTap: () => homeController.splitTabLeft(item),
                      child: const Padding(
                        padding: EdgeInsets.all(2.0),
                        child: Icon(
                          Icons.west_rounded,
                          size: 11,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Tooltip(
                    message: "Split Right",
                    child: InkWell(
                      onTap: () => homeController.splitTabRight(item),
                      child: const Padding(
                        padding: EdgeInsets.all(2.0),
                        child: Icon(
                          Icons.east_rounded,
                          size: 11,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  2.0.spaceX,
                  InkWell(
                    onTap: onRemove,
                    child: const Padding(
                      padding: EdgeInsets.all(2.0),
                      child: Icon(
                        Icons.close,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    });
  }
}
