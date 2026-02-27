-- 005_create_badges.sql
-- Бейджи пользователей

CREATE TABLE IF NOT EXISTS badges (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    UUID REFERENCES users(id),
    badge_type VARCHAR(50) NOT NULL,
    earned_at  TIMESTAMPTZ DEFAULT NOW()
);
