-- Library Management: bảng lịch mở cửa thư viện (module library/schedule).
-- DB chung để DB_SYNCHRONIZE=false nên bảng KHÔNG tự tạo -> chạy tay file này
-- một lần trên DB chung (prm_project) khi merge nhánh vào main.
--
-- Cách chạy (ví dụ với psql):
--   psql -h kepter.id.vn -U postgres -d prm_project -f be/sql/001_library_schedules.sql

-- 1) Kiểu enum cho cột type (khớp @Column enum của entity).
DO $$ BEGIN
  CREATE TYPE library_schedules_type_enum AS ENUM ('WEEKLY', 'SPECIAL');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- 2) Bảng library_schedules (khớp LibrarySchedule entity).
CREATE TABLE IF NOT EXISTS library_schedules (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  type          library_schedules_type_enum NOT NULL,
  day_of_week   integer,                 -- 0=CN..6=T7, dùng khi type=WEEKLY
  specific_date date,                    -- dùng khi type=SPECIAL
  open_time     time,
  close_time    time,
  is_closed     boolean NOT NULL DEFAULT false,
  note          text,
  is_active     boolean NOT NULL DEFAULT true,
  created_at    timestamptz NOT NULL DEFAULT now()
);
