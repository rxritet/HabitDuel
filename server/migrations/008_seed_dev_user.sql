-- 008_seed_dev_user.sql
-- Development seed user for local Docker login/testing.

INSERT INTO users (username, email, password_hash, wins, losses)
VALUES (
  'test',
  'test@test.test',
  '932f3c1b56257ce8539ac269d7aab42550dacf8818d075f0bdf1990562aae3ef',
  0,
  0
)
ON CONFLICT (email) DO UPDATE
SET username = EXCLUDED.username,
    password_hash = EXCLUDED.password_hash;