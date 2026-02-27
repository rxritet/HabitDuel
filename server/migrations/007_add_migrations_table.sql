-- 007_add_migrations_table.sql
-- Служебная таблица миграций (создаётся скриптом migrate.dart при первом запуске,
-- эта миграция нужна для фиксации версии в самой таблице)

CREATE TABLE IF NOT EXISTS schema_migrations (
    version    VARCHAR(50) PRIMARY KEY,
    applied_at TIMESTAMPTZ DEFAULT NOW()
);
