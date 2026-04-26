class AppUpdateInfo {
  const AppUpdateInfo({
    required this.versionName,
    required this.versionCode,
    required this.apkUrl,
    this.title = 'Доступно обновление',
    this.changelog = const [],
    this.forceUpdate = false,
    this.enabled = true,
  });

  final String versionName;
  final int versionCode;
  final String apkUrl;
  final String title;
  final List<String> changelog;
  final bool forceUpdate;
  final bool enabled;

  bool get hasDownloadUrl => apkUrl.trim().isNotEmpty;
}
