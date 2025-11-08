-- Quick Fix for Admin Group NULL Issue
-- Run this in your MySQL/MariaDB database

-- Step 1: Create an admin group with a random 6-character code
INSERT INTO admin_groups (group_name, group_code, created_at, updated_at)
VALUES (
    'Main Organization',
    CONCAT(
        CHAR(65 + FLOOR(RAND() * 26)),
        CHAR(65 + FLOOR(RAND() * 26)),
        CHAR(65 + FLOOR(RAND() * 26)),
        FLOOR(RAND() * 10),
        FLOOR(RAND() * 10),
        FLOOR(RAND() * 10)
    ),
    NOW(),
    NOW()
);

-- Step 2: Get the ID of the newly created group
SET @new_group_id = LAST_INSERT_ID();

-- Step 3: Update the admin user with the new group ID
UPDATE users 
SET admin_group_id = @new_group_id,
    updated_at = NOW()
WHERE role = 'admin' 
  AND admin_group_id IS NULL;

-- Step 4: Verify the fix
SELECT 
    u.id AS user_id,
    u.name AS user_name,
    u.email,
    u.role,
    u.admin_group_id,
    ag.id AS group_id,
    ag.group_name,
    ag.group_code,
    ag.created_at AS group_created
FROM users u
LEFT JOIN admin_groups ag ON u.admin_group_id = ag.id
WHERE u.role = 'admin';

-- You should see the admin user now has an admin_group_id and group_code
