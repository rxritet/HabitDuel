import 'package:flutter/material.dart';

import '../../core/updates/app_update_service.dart';

Future<void> showAppUpdateDialog(
  BuildContext context, {
  required AppUpdateCheckResult result,
  required Future<void> Function() onDownload,
  Future<void> Function()? onLater,
}) async {
  final update = result.remote;
  if (update == null) return;

  await showDialog<void>(
    context: context,
    barrierDismissible: !update.forceUpdate,
    builder: (context) {
      final theme = Theme.of(context);
      return AlertDialog(
        title: Text(update.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Доступна версия ${update.versionName} (${update.versionCode}). '
                'У вас установлена ${result.currentVersionName} (${result.currentVersionCode}).',
              ),
              if (update.changelog.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Что нового',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...update.changelog.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 3, right: 8),
                          child: Icon(Icons.circle, size: 8),
                        ),
                        Expanded(child: Text(item)),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'После нажатия откроется ссылка на APK. Android предложит скачать и установить обновление.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (!update.forceUpdate)
            TextButton(
              onPressed: () async {
                if (onLater != null) {
                  await onLater();
                }
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Позже'),
            ),
          FilledButton.icon(
            onPressed: () async {
              await onDownload();
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            icon: const Icon(Icons.download_outlined),
            label: const Text('Скачать'),
          ),
        ],
      );
    },
  );
}
