-- Axodus Trading Suit - PostgreSQL bootstrap
-- The postgres image already creates POSTGRES_USER and POSTGRES_DB.
-- Keep this file idempotent and free of environment-specific usernames.

CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
