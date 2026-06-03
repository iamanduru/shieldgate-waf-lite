# WAF Lite Database Setup

This folder contains the MySQL setup scripts for  WAF Lite.

## Database Engine

This project uses MySQL.

## Files

1. `001_create_database.sql`  
   Creates the `waf` database.

2. `002_create_restricted_user.sql`  
   Shows how to create a restricted MySQL user for the backend application.  
   Do not commit real passwords.

3. `003_create_tables.sql`  
   Creates all required application tables.

4. `004_seed_default_data.sql`  
   Inserts the default tenant and default protection config.

5. `005_stored_procedures.sql`  
   Creates stored procedures for decision logging, event logging, audit logging, reporting, and cleanup.

## Setup Order

Run the files in this order:

```sql
001_create_database.sql
002_create_restricted_user.example.sql
003_create_tables.sql
004_seed_default_data.sql
005_stored_procedures.sql