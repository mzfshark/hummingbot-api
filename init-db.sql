-- Safety net for PostgreSQL initialization
-- PostgreSQL auto-creates user/db from POSTGRES_USER, POSTGRES_DB env vars
-- This script only runs on first container initialization

-- Ensure proper permissions on public schema
GRANT ALL ON SCHEMA public TO trinity;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO trinity;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO trinity;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO trinity;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO trinity;
