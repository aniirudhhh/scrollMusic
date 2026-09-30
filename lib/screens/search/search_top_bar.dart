import 'package:flutter/material.dart';
import '../../theme/search_theme.dart';

class SearchTopBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isEditing;
  final VoidCallback onClear;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onTapSearchField;
  final ValueChanged<String> onChanged;
  final String hintText;

  const SearchTopBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isEditing,
    required this.onClear,
    required this.onSubmitted,
    required this.onTapSearchField,
    required this.onChanged,
    this.hintText = 'Search...',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56.0,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: SearchTheme.surfaceColor,
              borderRadius: BorderRadius.circular(28.0),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTapSearchField,
                child: SizedBox(
                  height: 48,
                  child: Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: isEditing
                              ? TextField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  onSubmitted: onSubmitted,
                                  onChanged: onChanged,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: hintText,
                                    hintStyle: const TextStyle(
                                      color: SearchTheme.secondaryText,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                  textInputAction: TextInputAction.search,
                                  maxLines: 1,
                                )
                              : Text(
                                  controller.text.isEmpty
                                      ? hintText
                                      : controller.text,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: controller.text.isEmpty
                                        ? FontWeight.w400
                                        : FontWeight.w600,
                                    color: controller.text.isEmpty
                                        ? SearchTheme.secondaryText
                                        : Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      if (controller.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: onClear,
                          splashRadius: 20,
                        ),
                      if (controller.text.isEmpty)
                        const SizedBox(width: 16), // Padding if no clear icon
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

