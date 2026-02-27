# ⚔️ HabitDuel

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-%23316192.svg?style=for-the-badge&logo=postgresql&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-In%20Development-orange?style=for-the-badge)

**HabitDuel** — мобильное приложение для соревновательного трекинга привычек. Брось вызов другу или незнакомцу: кто дольше держит streak по привычке — тот побеждает. Никаких курсов, никакого edtech — только мотивация через здоровую конкуренцию.

---

## 💡 Концепция

Большинство трекеров привычек скучны и бросаются через неделю. HabitDuel добавляет **социальный контракт**: ты публично берёшь обязательство перед соперником. Проиграл — получаешь публичный "позор" (streak сбрасывается, соперник видит твой провал). Победил — растёт рейтинг и счётчик побед.

---

## ✨ Ключевые фичи

### ⚔️ Дуэли
- Создать дуэль по привычке (название, описание, длительность в днях)
- Пригласить друга по username или принять случайный вызов
- Статусы дуэли: `pending` → `active` → `completed` / `abandoned`

### 🔥 Streak-система
- Ежедневное подтверждение выполнения привычки (check-in)
- Автоматический сброс streak при пропуске дня
- История check-in'ов с датами

### 📊 Realtime-обновления
- Оба участника видят прогресс соперника в реальном времени (WebSocket)
- Push-уведомление при пропуске соперника: "Твой соперник сломал streak — атакуй!"

### 🏆 Рейтинг и профиль
- Личный профиль: win/loss, текущие дуэли, история
- Глобальный лидерборд по победам
- Бейджи за серии побед (3, 5, 10 побед подряд)

### 🔐 Авторизация
- Регистрация и вход по email/паролю
- JWT-токены, хранение в secure storage

---

## 🛠️ Tech Stack

| Слой | Технология |
| :--- | :--- |
| **Мобильный клиент** | Flutter 3.x / Dart |
| **State Management** | Riverpod |
| **HTTP-клиент** | Dio + Retrofit |
| **WebSocket** | `web_socket_channel` |
| **Локальное хранение** | `flutter_secure_storage` (токены), `shared_preferences` (настройки) |
| **Push-уведомления** | `flutter_local_notifications` |
| **Бэкенд** | Dart (`shelf` + `shelf_router`) |
| **База данных** | PostgreSQL 16 |
| **ORM** | `postgres` (dart-pg драйвер) |

---

## 📂 Архитектура (Clean Architecture)

```
lib/
├── core/
│   ├── constants/
│   ├── errors/           # Failure классы
│   ├── network/          # Dio client, interceptors
│   └── utils/
├── data/
│   ├── datasources/      # RemoteDataSource (API calls)
│   ├── models/           # JSON-сериализация (User, Duel, CheckIn)
│   └── repositories/     # Реализации репозиториев
├── domain/
│   ├── entities/         # Чистые Dart-классы (User, Duel, CheckIn)
│   ├── repositories/     # Абстрактные интерфейсы
│   └── usecases/         # CreateDuel, CheckIn, GetLeaderboard...
├── presentation/
│   ├── providers/        # Riverpod providers
│   ├── screens/
│   │   ├── auth/         # login_screen, register_screen
│   │   ├── home/         # home_screen (список активных дуэлей)
│   │   ├── duel/         # duel_detail_screen, create_duel_screen
│   │   ├── profile/      # profile_screen
│   │   └── leaderboard/  # leaderboard_screen
│   └── widgets/          # streak_card, duel_tile, badge_chip...
└── main.dart
```

**Бэкенд (Dart/shelf):**
```
server/
├── bin/
│   └── server.dart       # Точка входа
├── lib/
│   ├── db/               # PostgreSQL connection pool
│   ├── handlers/         # auth, duels, checkins, leaderboard
│   ├── middleware/        # JWT auth middleware
│   ├── models/           # Dart-модели БД
│   └── websocket/        # WebSocket handler
└── pubspec.yaml
```

---

## 🗄️ Схема БД (PostgreSQL)

```sql
-- Пользователи
CREATE TABLE users (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username    VARCHAR(50) UNIQUE NOT NULL,
    email       VARCHAR(255) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    wins        INT DEFAULT 0,
    losses      INT DEFAULT 0,
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Дуэли
CREATE TABLE duels (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    habit_name   VARCHAR(100) NOT NULL,
    description  TEXT,
    creator_id   UUID REFERENCES users(id),
    opponent_id  UUID REFERENCES users(id),
    status       VARCHAR(20) DEFAULT 'pending', -- pending|active|completed|abandoned
    duration_days INT NOT NULL,
    starts_at    TIMESTAMPTZ,
    ends_at      TIMESTAMPTZ,
    created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- Стрики участников дуэли
CREATE TABLE duel_participants (
    id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    duel_id   UUID REFERENCES duels(id) ON DELETE CASCADE,
    user_id   UUID REFERENCES users(id),
    streak    INT DEFAULT 0,
    last_checkin DATE,
    UNIQUE(duel_id, user_id)
);

-- История чек-инов
CREATE TABLE checkins (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    duel_id    UUID REFERENCES duels(id) ON DELETE CASCADE,
    user_id    UUID REFERENCES users(id),
    checked_at TIMESTAMPTZ DEFAULT NOW(),
    note       TEXT
);

-- Бейджи
CREATE TABLE badges (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID REFERENCES users(id),
    badge_type  VARCHAR(50) NOT NULL, -- wins_3, wins_5, wins_10...
    earned_at   TIMESTAMPTZ DEFAULT NOW()
);
```

---

## 🗃️ DB Migrations & Indexes Checklist

Все миграции лежат в `server/migrations/` в виде нумерованных SQL-файлов.
Применяются последовательно скриптом `server/bin/migrate.dart`.

### Порядок миграций

| Файл | Описание |
| :--- | :--- |
| `001_create_users.sql` | Таблица `users` |
| `002_create_duels.sql` | Таблица `duels` |
| `003_create_duel_participants.sql` | Таблица `duel_participants` |
| `004_create_checkins.sql` | Таблица `checkins` |
| `005_create_badges.sql` | Таблица `badges` |
| `006_add_indexes.sql` | Все индексы (см. ниже) |
| `007_add_migrations_table.sql` | Служебная таблица `schema_migrations` |

### Индексы (006_add_indexes.sql)

```sql
-- Быстрый поиск дуэлей пользователя (домашний экран)
CREATE INDEX idx_duels_creator ON duels(creator_id);
CREATE INDEX idx_duels_opponent ON duels(opponent_id);
CREATE INDEX idx_duels_status ON duels(status);

-- Быстрая проверка "уже check-in сегодня?" (антифрод)
CREATE INDEX idx_checkins_duel_user_date
    ON checkins(duel_id, user_id, (checked_at::date));

-- Стрики участников по дуэли
CREATE INDEX idx_dp_duel ON duel_participants(duel_id);
CREATE INDEX idx_dp_user ON duel_participants(user_id);

-- Лидерборд: сортировка по wins DESC
CREATE INDEX idx_users_wins ON users(wins DESC);

-- Бейджи пользователя
CREATE INDEX idx_badges_user ON badges(user_id);
```

### Служебная таблица schema_migrations

```sql
CREATE TABLE IF NOT EXISTS schema_migrations (
    version     VARCHAR(50) PRIMARY KEY,
    applied_at  TIMESTAMPTZ DEFAULT NOW()
);
```

> Скрипт `migrate.dart` перед каждой миграцией проверяет `schema_migrations`.
> Уже применённые версии — пропускаются. Идемпотентно.

---

## 🌐 MVP API Contract

Базовый URL: `http://localhost:8080`  
Авторизованные запросы требуют заголовка: `Authorization: Bearer <jwt_token>`

---

### POST `/auth/register`

**Request:**
```json
{
  "username": "rxritet",
  "email": "user@example.com",
  "password": "securePass123"
}
```

**Response `201`:**
```json
{
  "id": "a1b2c3d4-...",
  "username": "rxritet",
  "email": "user@example.com",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Ошибки:**
```json
// 409 — username или email уже занят
{ "error": "username_taken" }
```

---

### POST `/auth/login`

**Request:**
```json
{
  "email": "user@example.com",
  "password": "securePass123"
}
```

**Response `200`:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "a1b2c3d4-...",
    "username": "rxritet",
    "wins": 3,
    "losses": 1
  }
}
```

**Ошибки:**
```json
// 401 — неверный email или пароль
{ "error": "invalid_credentials" }
```

---

### POST `/duels`

> Требует JWT.

**Request:**
```json
{
  "habit_name": "30 приседаний в день",
  "description": "Каждый день до 23:59 по местному времени",
  "duration_days": 14,
  "opponent_username": "friend42"  // опционально, без него — открытый вызов
}
```

**Response `201`:**
```json
{
  "id": "duel-uuid-...",
  "habit_name": "30 приседаний в день",
  "status": "pending",
  "creator": { "id": "...", "username": "rxritet" },
  "opponent": { "id": "...", "username": "friend42" },
  "duration_days": 14,
  "created_at": "2026-02-27T07:00:00Z"
}
```

---

### POST `/duels/:id/accept`

> Требует JWT. Только для пользователя-соперника со статусом `pending`.

**Response `200`:**
```json
{
  "id": "duel-uuid-...",
  "status": "active",
  "starts_at": "2026-02-27T07:20:00Z",
  "ends_at": "2026-03-13T07:20:00Z"
}
```

**Ошибки:**
```json
// 403 — ты не участник этой дуэли
{ "error": "forbidden" }
// 409 — дуэль уже не в статусе pending
{ "error": "duel_not_pending" }
```

---

### POST `/duels/:id/checkin`

> Требует JWT. Максимум 1 раз в сутки (по UTC-дате `checked_at`).

**Request:**
```json
{
  "note": "Сделал 35 раз, не 30 💪"  // опционально
}
```

**Response `201`:**
```json
{
  "checkin_id": "ci-uuid-...",
  "duel_id": "duel-uuid-...",
  "user_id": "a1b2c3d4-...",
  "new_streak": 5,
  "checked_at": "2026-02-27T08:15:00Z"
}
```

**Ошибки:**
```json
// 409 — check-in на сегодня уже есть
{ "error": "already_checked_in" }
// 403 — дуэль не в статусе active
{ "error": "duel_not_active" }
```

---

### GET `/duels`

> Требует JWT. Возвращает все дуэли текущего пользователя.

**Response `200`:**
```json
{
  "duels": [
    {
      "id": "duel-uuid-...",
      "habit_name": "30 приседаний в день",
      "status": "active",
      "my_streak": 5,
      "opponent_streak": 3,
      "opponent_username": "friend42",
      "ends_at": "2026-03-13T07:20:00Z"
    }
  ]
}
```

---

### GET `/leaderboard`

**Query params:** `?limit=50&offset=0`

**Response `200`:**
```json
{
  "leaderboard": [
    { "rank": 1, "username": "champion99", "wins": 42, "losses": 3 },
    { "rank": 2, "username": "rxritet",    "wins": 38, "losses": 7 }
  ]
}
```

---

### WS `/ws/duels/:id`

> Требует JWT в query-параметре: `/ws/duels/:id?token=<jwt>`

**Сервер пушит события:**

```json
// Соперник сделал check-in
{
  "event": "checkin_created",
  "data": {
    "user_id": "opponent-uuid",
    "username": "friend42",
    "new_streak": 4,
    "checked_at": "2026-02-27T09:00:00Z"
  }
}

// Соперник сломал streak (пропустил день)
{
  "event": "streak_broken",
  "data": {
    "user_id": "opponent-uuid",
    "username": "friend42",
    "streak_reset_to": 0
  }
}

// Дуэль завершена
{
  "event": "duel_completed",
  "data": {
    "winner_id": "a1b2c3d4-...",
    "winner_username": "rxritet",
    "my_final_streak": 14,
    "opponent_final_streak": 9
  }
}
```

---

## 🌐 REST API (сводная таблица)

| Метод | URL | Описание |
| :--- | :--- | :--- |
| `POST` | `/auth/register` | Регистрация |
| `POST` | `/auth/login` | Вход, получение JWT |
| `GET` | `/users/me` | Профиль текущего пользователя |
| `GET` | `/users/:username` | Профиль по username |
| `POST` | `/duels` | Создать дуэль |
| `GET` | `/duels` | Список своих дуэлей |
| `GET` | `/duels/:id` | Детали дуэли |
| `POST` | `/duels/:id/accept` | Принять вызов |
| `POST` | `/duels/:id/checkin` | Отметить выполнение привычки |
| `GET` | `/leaderboard` | Топ-50 по победам |
| `WS` | `/ws/duels/:id` | WebSocket-канал дуэли |

---

## 🚀 Запуск проекта

### Требования
- Flutter SDK 3.x
- Dart SDK ^3.0.0
- PostgreSQL 16
- Docker (опционально)

### 1. Клонировать репозиторий
```bash
git clone https://github.com/rxritet/HabitDuel.git
cd HabitDuel
```

### 2. Запустить PostgreSQL
```bash
# Через Docker
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
cd server
dart run bin/server.dart
# Сервер стартует на http://localhost:8080
```

### 5. Запустить Flutter-приложение
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

MIT License — используй свободно.
