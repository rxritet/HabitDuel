# ⚔️ HabitDuel

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-%23316192.svg?style=for-the-badge&logo=postgresql&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-In%20Development-orange?style=for-the-badge)

**HabitDuel** — мобильное приложение для соревновательного трекинга привычек.  
Брось вызов другу или незнакомцу: кто дольше держит streak — тот побеждает.  
Никакого edtech, только мотивация через здоровую конкуренцию.

> 📄 Полное ТЗ проекта: [SPEC.md](./SPEC.md)

---

## 📂 Структура проекта

```
HabitDuel/
├── lib/                    # Flutter-приложение
│   ├── core/               # Константы, ошибки, сеть
│   ├── data/               # Datasources, модели, репозитории
│   ├── domain/             # Entities, usecases, интерфейсы
│   ├── presentation/       # Экраны, виджеты, Riverpod providers
│   └── main.dart
├── server/                 # Dart-бэкенд (shelf)
│   ├── bin/
│   │   ├── server.dart     # Точка входа
│   │   └── migrate.dart    # Скрипт миграций
│   ├── lib/
│   │   ├── db/             # PostgreSQL connection pool
│   │   ├── handlers/       # auth, duels, checkins, leaderboard
│   │   ├── middleware/     # JWT middleware
│   │   ├── models/         # Dart-модели БД
│   │   └── websocket/      # WebSocket handler
│   └── migrations/         # SQL-файлы миграций (001..007)
└── README.md
```

---

## 🚀 Запуск

### Требования
- Flutter SDK 3.x
- Dart SDK ^3.0.0
- PostgreSQL 16 (или Docker)

### 1. Клонировать репозиторий
```bash
git clone https://github.com/rxritet/HabitDuel.git
cd HabitDuel
```

### 2. Запустить PostgreSQL
```bash
docker run --name habitduel-db \
  -e POSTGRES_USER=habitduel \
  -e POSTGRES_PASSWORD=secret \
  -e POSTGRES_DB=habitduel \
  -p 5432:5432 -d postgres:16
```

### 3. Применить миграции
```bash
cd server
dart run bin/migrate.dart
```

### 4. Запустить бэкенд
```bash
dart run bin/server.dart
# → http://localhost:8080
```

### 5. Запустить Flutter
```bash
cd ..
flutter pub get
flutter run
```

---

## 📅 Roadmap

- [x] Инициализация проекта
- [ ] Авторизация (register/login, JWT)
- [ ] CRUD дуэлей
- [ ] Streak + check-in механика
- [ ] WebSocket realtime
- [ ] Лидерборд
- [ ] Push-уведомления
- [ ] Бейджи
- [ ] UI полировка + анимации

---

## 📄 Лицензия

MIT License
