## 🔗 Related Repositories

This is the **backend** (REST API) for the DB_dentista_Consultorio

| Part | Repository |
|---|---|
| 🖥️ Frontend (Angular) | [dental-system-frontend](https://github.com/Dianaqwert/DB_dentista_Consultorio) |
| ⚙️ Backend (Node.js) | You are here |

---

## Overview

This Node.js + Express API serves as the middleware between the Angular frontend 
and the PostgreSQL database. It handles all business logic, SQL transactions, 
and exposes a REST API consumed by the frontend.

##  Database Setup (Required)

This project requires **PostgreSQL** installed locally via [pgAdmin](https://www.pgadmin.org/).

### Steps:
1. Open pgAdmin and create a new database (e.g. `dental_system`)
2. Open the Query Tool on that database
3. Run the script **in this order**:
   - `database/schema.sql` → creates all tables , views, triggers , etc.
4. Copy `.env.example` to `.env` and fill in your credentials:
```bash
   cp .env.example .env
```
5. Install dependencies and start the server:
```bash
   npm install
   npm start
```
