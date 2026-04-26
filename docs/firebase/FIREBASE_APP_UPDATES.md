# Firebase APK Updates

HabitDuel теперь умеет проверять новую Android APK-версию через Firestore и
показывать пользователю диалог обновления.

## Как это работает

1. Приложение читает документ `app_config/android_update` в Firestore.
2. Сравнивает `versionCode` документа с текущим `buildNumber` приложения.
3. Если версия новее, показывает диалог.
4. По кнопке `Скачать` открывает ссылку на APK.
5. Пользователь сам скачивает и устанавливает обновление.

## Документ Firestore

Коллекция:

```text
app_config
```

Документ:

```text
android_update
```

Пример полей:

```json
{
  "enabled": true,
  "title": "Доступно обновление HabitDuel",
  "versionName": "1.0.1",
  "versionCode": 2,
  "apkUrl": "https://your-public-link/app-release.apk",
  "forceUpdate": false,
  "changelog": [
    "Исправлены визуальные баги в статистике",
    "Добавлен новый рейтинг игроков",
    "Появилось редактирование профиля"
  ]
}
```

## Что важно

- `versionCode` должен быть больше, чем текущий `buildNumber` в приложении.
- `apkUrl` должен быть публичной прямой ссылкой на APK.
- Если `forceUpdate = true`, пользователь не сможет просто закрыть диалог.
- Если `enabled = false`, проверка обновления игнорируется.

## Где пользователю видно обновление

- Автоматически на главном экране после входа.
- Вручную через `Settings -> Check for updates`.

## Как публиковать новую версию

1. Соберите APK.
2. Загрузите APK в Firebase Storage, Google Drive, GitHub Releases или другой хостинг.
3. Возьмите публичную ссылку на файл.
4. Обновите документ `app_config/android_update` в Firestore.

## Сборка APK

Пример:

```powershell
C:\flutter\bin\flutter.bat build apk --release --dart-define=API_BASE_URL=http://192.168.123.9:8080
```

## Publish script

В проекте есть helper-скрипт:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\publish-firebase-update.ps1 `
  -ApiBaseUrl "http://192.168.123.9:8080" `
  -PublicApkUrl "https://firebasestorage.googleapis.com/..." `
  -Changelog "Новый рейтинг" "Редактирование профиля"
```

Что он делает:

1. Собирает release APK.
2. Копирует его в `build/releases/`.
3. Даёт файлу имя вида `HabitDuel-v1.0.0+1-release.apk`.
4. Генерирует JSON для документа `app_config/android_update`.

Если на машине установлен `gsutil`, можно ещё передать bucket:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\publish-firebase-update.ps1 `
  -StorageBucket "your-project.firebasestorage.app" `
  -Changelog "UI polish" "Bug fixes"
```

После этого останется взять public download URL и записать его в Firestore.

## Замечание по ссылке

Лучше всего использовать ссылку, которая сразу отдаёт APK-файл, а не страницу
предпросмотра. Для Google Drive обычная share-ссылка часто ведёт на страницу,
а не на прямое скачивание.
