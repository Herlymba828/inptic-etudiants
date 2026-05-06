-- Extensions PostgreSQL utiles pour INPTIC RH
-- Exécuté automatiquement au premier démarrage du conteneur

-- pg_stat_statements : analyse des requêtes lentes
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- uuid-ossp : génération d'UUID si besoin futur
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Paramètres de performance (appliqués à la session d'init)
ALTER SYSTEM SET shared_preload_libraries = 'pg_stat_statements';
ALTER SYSTEM SET pg_stat_statements.track = 'all';
ALTER SYSTEM SET log_min_duration_statement = 1000;  -- log requêtes > 1s
ALTER SYSTEM SET max_connections = 100;
ALTER SYSTEM SET shared_buffers = '256MB';
ALTER SYSTEM SET effective_cache_size = '768MB';
ALTER SYSTEM SET work_mem = '4MB';
ALTER SYSTEM SET maintenance_work_mem = '64MB';
ALTER SYSTEM SET checkpoint_completion_target = 0.9;
ALTER SYSTEM SET wal_buffers = '16MB';
ALTER SYSTEM SET default_statistics_target = 100;

SELECT pg_reload_conf();
