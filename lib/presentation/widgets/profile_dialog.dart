import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/home_page_controller.dart';
import '../../domain/tab_model.dart';

class ProfileDialog extends StatefulWidget {
  const ProfileDialog({super.key});

  @override
  State<ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<ProfileDialog> {
  final HomePageController controller = Get.find<HomePageController>();
  final TextEditingController _customNameController = TextEditingController();

  @override
  void dispose() {
    _customNameController.dispose();
    super.dispose();
  }

  String _formatDate(dynamic dateVal) {
    if (dateVal == null) return "";
    try {
      final dt = DateTime.parse(dateVal.toString());
      final y = dt.year;
      final m = dt.month.toString().padLeft(2, '0');
      final d = dt.day.toString().padLeft(2, '0');
      final hr = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return "$y-$m-$d $hr:$min";
    } catch (_) {
      return dateVal.toString();
    }
  }

  String _formatSize(String text) {
    final bytes = text.length;
    if (bytes < 1024) return "$bytes B";
    final kb = bytes / 1024.0;
    if (kb < 1024) return "${kb.toStringAsFixed(1)} KB";
    final mb = kb / 1024.0;
    return "${mb.toStringAsFixed(1)} MB";
  }

  void _showEditDialog(BuildContext context, TabModel item) {
    final nameCtrl = TextEditingController(text: item.name?.toString() ?? "");
    final dataCtrl = TextEditingController(text: item.data?.toString() ?? "");
    final isDark = controller.isDark.value == 1;

    final cardColor = isDark ? const Color(0xFF161B22) : Colors.white;
    final textColor = isDark ? const Color(0xFFE6EDF3) : const Color(0xFF24292F);
    final subtitleColor = isDark ? const Color(0xFF8B949E) : Colors.black54;

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isDark ? const Color(0xFF30363D) : const Color(0xFFD0D7DE)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Edit Saved Tab",
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    color: subtitleColor,
                    onPressed: () => Get.back(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: "Tab Name",
                  labelStyle: TextStyle(color: subtitleColor, fontSize: 13),
                  border: const OutlineInputBorder(),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                ),
                style: TextStyle(color: textColor, fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dataCtrl,
                maxLines: 8,
                decoration: InputDecoration(
                  labelText: "JSON Data Content",
                  labelStyle: TextStyle(color: subtitleColor, fontSize: 13),
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.all(12),
                ),
                style: TextStyle(
                  color: textColor,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: Text("Cancel", style: TextStyle(color: subtitleColor)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigoAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                    ),
                    onPressed: () {
                      controller.editSavedTabInList(
                        item,
                        newName: nameCtrl.text.trim(),
                        newData: dataCtrl.text,
                      );
                      Get.back();
                    },
                    child: const Text("Save Changes"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = controller.isDark.value == 1;
      final savedList = controller.savedTabsList;

      final cardColor = isDark ? const Color(0xFF161B22) : Colors.white;
      final textColor = isDark ? const Color(0xFFE6EDF3) : const Color(0xFF24292F);
      final subtitleColor = isDark ? const Color(0xFF8B949E) : Colors.black54;
      final borderColor = isDark ? const Color(0xFF30363D) : const Color(0xFFD0D7DE);

      final activeTabName = controller.selected.name?.toString() ?? "";

      return Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 540,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.indigoAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.collections_bookmark_rounded,
                          color: Colors.indigoAccent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Saved Tabs",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          Text(
                            "Save, view, edit, load or delete tabs locally",
                            style: TextStyle(fontSize: 11, color: subtitleColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                    color: subtitleColor,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Save Current Active Tab Row
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0D1117)
                      : const Color(0xFFF6F8FA),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Save Active Tab",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        if (activeTabName.isNotEmpty)
                          Text(
                            "Active: $activeTabName",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.indigoAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _customNameController,
                            decoration: InputDecoration(
                              hintText:
                                  "Custom name (optional, defaults to tab keyword)",
                              hintStyle:
                                  TextStyle(color: subtitleColor, fontSize: 12),
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 12),
                            ),
                            style: TextStyle(color: textColor, fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigoAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                          ),
                          onPressed: () {
                            controller.saveCurrentTabToSavedList(
                              customName: _customNameController.text,
                            );
                            _customNameController.clear();
                          },
                          icon: const Icon(Icons.bookmark_add_rounded, size: 16),
                          label: const Text("Save Tab",
                              style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // List Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Saved Tabs List (${savedList.length})",
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Saved Tabs List
              if (savedList.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Icon(Icons.bookmark_outline, size: 36, color: subtitleColor),
                      const SizedBox(height: 8),
                      Text(
                        "No saved tabs yet.",
                        style: TextStyle(
                            color: subtitleColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Click 'Save Tab' above or from option menu to save tabs.",
                        style: TextStyle(color: subtitleColor, fontSize: 11),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  constraints: const BoxConstraints(maxHeight: 260),
                  decoration: BoxDecoration(
                    border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: savedList.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: borderColor),
                    itemBuilder: (context, index) {
                      final item = savedList[index];
                      final dataStr = item.data?.toString() ?? "";
                      final dateStr = _formatDate(item.updatedAt);
                      final sizeStr = _formatSize(dataStr);

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF0D1117)
                                    : const Color(0xFFF6F8FA),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.data_object_rounded,
                                size: 16,
                                color: Colors.indigoAccent,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        item.name.toString().startsWith("Tab")
                                            ? item.name.toString()
                                            : "Tab ${item.name}",
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "$sizeStr • $dateStr",
                                        style: TextStyle(
                                            fontSize: 10, color: subtitleColor),
                                      ),
                                    ],
                                  ),
                                  if (dataStr.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      dataStr.replaceAll(RegExp(r'\s+'), ' '),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontFamily: 'monospace',
                                        color: subtitleColor,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Load / Open Button
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.indigoAccent,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 6),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4)),
                                  ),
                                  onPressed: () =>
                                      controller.loadSavedTabToActive(item),
                                  icon: const Icon(Icons.file_open_outlined,
                                      size: 13),
                                  label: const Text("Load",
                                      style: TextStyle(fontSize: 11)),
                                ),
                                const SizedBox(width: 6),
                                // Edit Button
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 16),
                                  color: Colors.indigoAccent,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () =>
                                      _showEditDialog(context, item),
                                  tooltip: "Edit Name / Data",
                                ),
                                const SizedBox(width: 6),
                                // Delete Button
                                IconButton(
                                  icon:
                                      const Icon(Icons.delete_outline, size: 16),
                                  color: Colors.redAccent,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () =>
                                      controller.deleteSavedTabFromList(item.id),
                                  tooltip: "Delete Saved Tab",
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}
