import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../data/library_manager.dart';
import '../../models/playlist.dart';
import '../../core/utils/app_toast.dart';

class PlaylistEditDialog extends StatefulWidget {
  const PlaylistEditDialog({super.key, this.existingPlaylist});

  final Playlist? existingPlaylist;

  static void show(BuildContext context, {Playlist? existingPlaylist}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PlaylistEditDialog(existingPlaylist: existingPlaylist),
    );
  }

  @override
  State<PlaylistEditDialog> createState() => _PlaylistEditDialogState();
}

class _PlaylistEditDialogState extends State<PlaylistEditDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingPlaylist?.name ?? '');
    _descController = TextEditingController(text: widget.existingPlaylist?.description ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }


  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      AppToast.show(context, 'Playlist name cannot be empty');
      return;
    }

    final desc = _descController.text.trim();
    final library = context.read<LibraryManager>();

    if (widget.existingPlaylist != null) {
      library.updatePlaylist(
        widget.existingPlaylist!.id,
        name,
        desc.isEmpty ? null : desc,
        null,
      );
      AppToast.show(context, 'Playlist updated');
    } else {
      library.createPlaylist(
        name,
        description: desc.isEmpty ? null : desc,
        imagePath: null,
      );
      AppToast.show(context, 'Playlist created');
    }

    Navigator.pop(context);
  }


  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1C1C1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.existingPlaylist != null ? 'Edit Playlist' : 'New Playlist',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white70,
                    size: 24,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Name Field
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.left,
              decoration: InputDecoration(
                hintText: 'Playlist Name',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              ),
            ),
            const SizedBox(height: 12),
            
            // Description Field
            TextField(
              controller: _descController,
              style: const TextStyle(color: Colors.white70, fontSize: 15),
              textAlign: TextAlign.left,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Add a description...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              ),
            ),
            const SizedBox(height: 24),
            
            // Save Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF2D55),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 0,
                ),
                onPressed: _save,
                child: const Text('Save', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    ));
  }
}
