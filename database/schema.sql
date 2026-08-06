-- =============================================================================
-- Project:         B2B SaaS Customer Cohort & Retention Analytics Platform
-- File:            schema.sql
-- Role:            Senior Data Architect / PostgreSQL Database Administrator
-- Target Engine:   PostgreSQL 13+
-- Purpose:         Database initialization, schema creation, search path 
--                  configuration, and global administrative settings.
-- =============================================================================

--------------------------------------------------------------------------------
-- 1. DATABASE CREATION & CONNECTION INSTRUCTIONS
--------------------------------------------------------------------------------
-- To create and connect to the b2b_saas_analytics database in PostgreSQL:
--
-- CREATE DATABASE b2b_saas_analytics
--     WITH 
--     OWNER = postgres
--     ENCODING = 'UTF8'
--     LC_COLLATE = 'English_United States.1252'
--     LC_CTYPE = 'English_United States.1252'
--     TABLESPACE = pg_default
--     CONNECTION LIMIT = -1;
--
-- \c b2b_saas_analytics;
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 2. SCHEMA INITIALIZATION
--------------------------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS analytics;

--------------------------------------------------------------------------------
-- 3. SEARCH PATH CONFIGURATION
--------------------------------------------------------------------------------
-- Set search path to prioritize the analytics schema before public
SET search_path TO analytics, public;

--------------------------------------------------------------------------------
-- 4. SCHEMA DOCUMENTATION & COMMENTS
--------------------------------------------------------------------------------
COMMENT ON SCHEMA analytics IS 
'Production analytics schema for B2B SaaS Customer Cohort & Retention Analytics Platform. Stores normalized account, subscription, marketing, support, feature usage, and churn domain tables.';

--------------------------------------------------------------------------------
-- 5. DATABASE DESIGN & NAMING CONVENTIONS
--------------------------------------------------------------------------------
/*
   NAMING CONVENTIONS:
   1. All schema identifiers (tables, columns, views, indexes, constraints) MUST 
      use lowercase snake_case formatting.
   2. Table names are pluralized nouns representing domain entities 
      (e.g., accounts, subscriptions, feature_usage).
   3. Primary keys follow the pattern: {table_singular}_id or entity natural key 
      (e.g., account_id, subscription_id).
   4. Foreign keys match the target primary key name exactly for transparent join logic.
   5. Boolean flags use prefixes such as is_ or _flag (e.g., is_trial, churn_flag).
   6. Timestamps use suffix _at (e.g., submitted_at, closed_at), while calendar 
      dates use suffix _date (e.g., signup_date, start_date).
   7. Monetary amounts are explicitly typed as NUMERIC(12,2) with suffix _usd or _amount.

   FUTURE SCALABILITY & EXTENSIBILITY:
   - Schema Isolation: Decoupled under 'analytics' schema to allow future operational 
     staging (e.g., raw_staging, dbt_marts) without collision.
   - Partitioning Strategy: High-volume telemetry (feature_usage) is structured to 
     support declarative PostgreSQL range partitioning by usage_date if data volume exceeds 10M rows.
   - Auditability: Designed for seamless integration with CDC (Change Data Capture) 
     or temporal tables via trigger-based updated_at timestamps in Phase 2.
*/
