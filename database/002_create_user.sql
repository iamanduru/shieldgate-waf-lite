-- Run this file using a MySQL admin/root account.
-- Replace CHANGE_THIS_STRONG_PASSWORD with your real password locally.
-- Do NOT commit real passwords to GitHub.

CREATE USER IF NOT EXISTS 'waf_app'@'localhost'
IDENTIFIED BY 'CHANGE_THIS_STRONG_PASSWORD';

GRANT SELECT, INSERT, UPDATE, DELETE
ON waf.*
TO 'waf_app'@'localhost';

FLUSH PRIVILEGES;