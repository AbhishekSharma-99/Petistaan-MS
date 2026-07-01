-- init.sql

-- 1. Ensure the microservices database exists
CREATE DATABASE IF NOT EXISTS petistaan_owner;
CREATE DATABASE IF NOT EXISTS petistaan_pet;

-- 2. Grant explicit database-level permissions to the user.
-- (No implicit user creation or passwords here—let Docker env pass it)
GRANT ALL PRIVILEGES ON petistaan_owner.* TO 'petistaan_user'@'%';
GRANT ALL PRIVILEGES ON petistaan_pet.* TO 'petistaan_user'@'%';

-- Note: 'FLUSH PRIVILEGES' is omitted because modern MySQL executes 
-- privilege modifications dynamically in-memory instantly on GRANT.
