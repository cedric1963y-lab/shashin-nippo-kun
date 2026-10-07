import 'package:flutter/material.dart';

import '../format.dart';
import '../theme.dart';

class PhotoEditorResult {
  const PhotoEditorResult.saved({required this.memo, required this.takenAt})
    : deleted = false;

  const PhotoEditorResult.deleted() : deleted = true, memo = '', takenAt = null;

  final bool deleted;
  final String memo;
  final DateTime? takenAt;
}

class PhotoEditorScreen extends StatefulWidget {
  const PhotoEditorScreen({
    required this.title,
    required this.image,
    required this.initialTakenAt,
    required this.initialMemo,
    required this.saveLabel,
    this.allowDelete = false,
    super.key,
  });

  final String title;
  final ImageProvider image;
  final DateTime initialTakenAt;
  final String initialMemo;
  final String saveLabel;
  final bool allowDelete;

  @override
  State<PhotoEditorScreen> createState() => _PhotoEditorScreenState();
}

class _PhotoEditorScreenState extends State<PhotoEditorScreen> {
  late DateTime _takenAt = widget.initialTakenAt;
  late final TextEditingController _memo = TextEditingController(
    text: widget.initialMemo,
  );

  @override
  void dispose() {
    _memo.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _takenAt,
      firstDate: DateTime(2010),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      locale: const Locale('ja'),
    );
    if (picked == null) return;
    setState(() {
      _takenAt = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _takenAt.hour,
        _takenAt.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_takenAt),
      builder: (context, child) {
        return Localizations.override(
          context: context,
          locale: const Locale('ja'),
          child: child,
        );
      },
    );
    if (picked == null) return;
    setState(() {
      _takenAt = DateTime(
        _takenAt.year,
        _takenAt.month,
        _takenAt.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  void _save() {
    Navigator.pop(
      context,
      PhotoEditorResult.saved(memo: _memo.text, takenAt: _takenAt),
    );
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('この写真を削除しますか？'),
          content: const Text('日報にまだ入れていなければ、無料プランの枚数に空きが戻ります。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                '削除',
                style: TextStyle(color: AppColors.danger),
              ),
            ),
          ],
        );
      },
    );
    if (confirmed == true && mounted) {
      Navigator.pop(context, const PhotoEditorResult.deleted());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Expanded(
            child: ColoredBox(
              color: AppColors.slate,
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(
                  child: Image(
                    image: widget.image,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Material(
            color: AppColors.card,
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OutlinedButton(
                      onPressed: _pickDate,
                      child: Text(formatJapaneseDate(_takenAt)),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: _pickTime,
                      child: Text('時刻 ${formatTime(_takenAt)}'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      key: const Key('photo-memo'),
                      controller: _memo,
                      maxLength: 80,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'メモ（任意）',
                        hintText: '例）外壁下地、2階南側',
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      key: const Key('save-photo'),
                      onPressed: _save,
                      child: Text(widget.saveLabel),
                    ),
                    if (widget.allowDelete)
                      TextButton(
                        onPressed: _delete,
                        child: const Text(
                          'この写真を削除',
                          style: TextStyle(color: AppColors.danger),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
