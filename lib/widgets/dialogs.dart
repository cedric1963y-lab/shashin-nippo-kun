import 'package:flutter/material.dart';

import '../errors.dart';
import '../plan/limits.dart';
import '../screens/premium_screen.dart';
import '../theme.dart';

Future<void> showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
  return Future<void>.value();
}

Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(body, style: const TextStyle(height: 1.45)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              confirmLabel,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

class SiteDraft {
  const SiteDraft({required this.name, required this.note});

  final String name;
  final String note;
}

Future<SiteDraft?> showSiteDialog(
  BuildContext context, {
  String title = '現場を追加',
  String saveLabel = '追加',
  String initialName = '',
  String initialNote = '',
}) {
  return showDialog<SiteDraft>(
    context: context,
    builder: (context) => _SiteDialog(
      title: title,
      saveLabel: saveLabel,
      initialName: initialName,
      initialNote: initialNote,
    ),
  );
}

class _SiteDialog extends StatefulWidget {
  const _SiteDialog({
    required this.title,
    required this.saveLabel,
    required this.initialName,
    required this.initialNote,
  });

  final String title;
  final String saveLabel;
  final String initialName;
  final String initialNote;

  @override
  State<_SiteDialog> createState() => _SiteDialogState();
}

class _SiteDialogState extends State<_SiteDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.initialName,
  );
  late final TextEditingController _note = TextEditingController(
    text: widget.initialNote,
  );
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  void _save() {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = '現場名を入力してください。');
      return;
    }
    Navigator.pop(context, SiteDraft(name: _name.text, note: _note.text));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('site-name'),
              controller: _name,
              autofocus: true,
              textInputAction: TextInputAction.next,
              maxLength: 40,
              decoration: const InputDecoration(
                labelText: '現場名',
                hintText: '例）南青山 戸建リフォーム',
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('site-note'),
              controller: _note,
              textInputAction: TextInputAction.done,
              maxLength: 80,
              decoration: const InputDecoration(
                labelText: 'メモ（任意）',
                hintText: '元請、住所など',
              ),
              onSubmitted: (_) => _save(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 4),
              Text(_error!, style: const TextStyle(color: AppColors.danger)),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('キャンセル'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    key: const Key('save-site'),
                    onPressed: _save,
                    child: Text(widget.saveLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showLimitDialog(BuildContext context, LimitKind kind) async {
  final (title, body) = switch (kind) {
    LimitKind.photos => (
      '写真の上限です',
      '無料プランでは写真を${PlanLimits.freePhotoLimit}枚まで保存できます。プレミアム（月額${PlanLimits.monthlyPriceLabel}）の契約中は上限がなくなります。期限が切れても、保存済みの写真は残ります。',
    ),
    LimitKind.reports => (
      '日報の上限です',
      '無料プランでは日報を${PlanLimits.freeReportLimit}件まで作成できます。作った日報の再共有は、削除するまで何度でも無料です。プレミアムの契約中は件数の上限が外れます。',
    ),
    LimitKind.photosPerReport => (
      '1件の枚数です',
      '1件の日報に入れられる写真は${PlanLimits.maxPhotosPerReport}枚までです。日を分けるか、選択を減らしてください。',
    ),
  };
  final wantsPremium = kind != LimitKind.photosPerReport;
  final open = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(body, style: const TextStyle(height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('閉じる'),
          ),
          if (wantsPremium)
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('プレミアムを見る'),
            ),
        ],
      );
    },
  );
  if (open == true && context.mounted) {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const PremiumScreen()));
  }
}

Future<T> runBlocking<T>(
  BuildContext context,
  String message,
  Future<T> Function() action,
) async {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return PopScope(
        canPop: false,
        child: Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: AppColors.orange),
                  const SizedBox(height: 16),
                  Text(message),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
  try {
    return await action();
  } finally {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}

Future<void> handleLimitOrMessage(BuildContext context, Object error) async {
  if (error is LimitReached) {
    await showLimitDialog(context, error.kind);
    return;
  }
  if (error is InvalidInput) {
    await showSnack(context, error.message);
    return;
  }
  await showSnack(context, '保存できませんでした。空き容量を確認してください。');
}
