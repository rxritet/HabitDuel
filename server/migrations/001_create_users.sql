-- 001_create_users.sql
-- Таблица пользователей

CREATE TABLE IF NOT EXISTS users (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username      VARCHAR(50)  UNIQUE NOT NULL,
    email         VARCHAR(255) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    wins          INT DEFAULT 0,
    losses        INT DEFAULT 0,
    created_at    TIMESTAMPTZ DEFAULT NOW()
);
