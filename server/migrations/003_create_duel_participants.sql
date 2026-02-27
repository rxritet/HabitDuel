-- 003_create_duel_participants.sql
-- Стрики участников дуэлей

CREATE TABLE IF NOT EXISTS duel_participants (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    duel_id      UUID REFERENCES duels(id) ON DELETE CASCADE,
    user_id      UUID REFERENCES users(id),
    streak       INT  DEFAULT 0,
    last_checkin DATE,
    UNIQUE(duel_id, user_id)
);
