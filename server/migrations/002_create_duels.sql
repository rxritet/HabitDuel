-- 002_create_duels.sql
-- Таблица дуэлей

CREATE TABLE IF NOT EXISTS duels (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    habit_name    VARCHAR(100) NOT NULL,
    description   TEXT,
    creator_id    UUID REFERENCES users(id),
    opponent_id   UUID REFERENCES users(id),
    status        VARCHAR(20) DEFAULT 'pending',
    duration_days INT NOT NULL,
    starts_at     TIMESTAMPTZ,
    ends_at       TIMESTAMPTZ,
    created_at    TIMESTAMPTZ DEFAULT NOW()
);
