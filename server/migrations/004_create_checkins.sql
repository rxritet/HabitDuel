-- 004_create_checkins.sql
-- История check-in'ов

CREATE TABLE IF NOT EXISTS checkins (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    duel_id    UUID REFERENCES duels(id) ON DELETE CASCADE,
    user_id    UUID REFERENCES users(id),
    checked_at TIMESTAMPTZ DEFAULT NOW(),
    note       TEXT
);
