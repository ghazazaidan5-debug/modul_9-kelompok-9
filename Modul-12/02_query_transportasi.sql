USE transport_db;

-- 1. Query Pengujian (Seleksi, Join, dan Proyeksi)
SELECT t.trip_id, t.started_at, r.route_name
FROM trips AS t
JOIN routes AS r ON r.route_id = t.route_id
WHERE t.route_id = 12 AND t.started_at >= '2026-11-01';

-- 2. Inspeksi Rencana Eksekusi & Selection Pushdown pada TiDB
EXPLAIN ANALYZE
SELECT t.trip_id, t.started_at, r.route_name
FROM trips AS t
JOIN routes AS r ON r.route_id = t.route_id
WHERE t.route_id = 12 AND t.started_at >= '2026-11-01';
