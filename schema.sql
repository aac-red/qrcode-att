-- =========================================================
-- Timecard — Supabase schema
-- Run this in: Supabase Dashboard → SQL Editor → New query
-- =========================================================

create extension if not exists pgcrypto;

-- ---------------------------------------------------------
-- Employees
-- ---------------------------------------------------------
create table if not exists employees (
  id uuid primary key default gen_random_uuid(),
  employee_code text unique not null,
  full_name text not null,
  company text not null,
  department text not null,
  created_at timestamptz not null default now()
);

create index if not exists idx_employees_code on employees (employee_code);

-- ---------------------------------------------------------
-- Attendance logs
-- (company/department/full_name are duplicated here on purpose
--  so the log keeps its own snapshot even if an employee record
--  changes later, and so exports don't need a join)
-- ---------------------------------------------------------
create table if not exists attendance_logs (
  id uuid primary key default gen_random_uuid(),
  employee_id uuid references employees(id) on delete set null,
  employee_code text not null,
  full_name text not null,
  company text not null,
  department text not null,
  log_type text not null check (log_type in ('time_in', 'time_out')),
  scanned_at timestamptz not null default now()
);

create index if not exists idx_logs_employee on attendance_logs (employee_id);
create index if not exists idx_logs_scanned_at on attendance_logs (scanned_at);

-- ---------------------------------------------------------
-- Row Level Security
-- This app is a kiosk that authenticates with the public
-- "anon" key, so policies below allow the anon role to
-- read/write. Tighten this later (e.g. behind a PIN, or a
-- Supabase Edge Function) once you move beyond a trusted
-- kiosk device on a private network.
-- ---------------------------------------------------------
alter table employees enable row level security;
alter table attendance_logs enable row level security;

create policy "anon can read employees" on employees
  for select to anon using (true);

create policy "anon can insert employees" on employees
  for insert to anon with check (true);

create policy "anon can read logs" on attendance_logs
  for select to anon using (true);

create policy "anon can insert logs" on attendance_logs
  for insert to anon with check (true);

-- Optional: allow updates/deletes from an authenticated admin only.
-- Skip this if you don't plan to add Supabase Auth.
-- create policy "authenticated can manage employees" on employees
--   for all to authenticated using (true) with check (true);
