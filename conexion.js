import pg from "pg";

export const pool = new pg.Pool({
  user: "postgres",
  host: "localhost",
  database: "dentistaConsultorio",
  password: "1666",
  port: 5432,
});
