-- ATTENDO MVP: run once in Supabase SQL Editor (test data only).
create table if not exists public.attendance_requests (
 id uuid primary key default gen_random_uuid(),
 student_id uuid not null references public.profiles(id),
 class_id uuid not null references public.classes(id),
 attendance_date date not null,
 request_type text not null check (request_type in ('tardy','absence','correction')),
 reason text not null check (char_length(trim(reason)) between 3 and 2000),
 review_status text not null default 'pending' check (review_status in ('pending','approved','rejected')),
 reviewed_by uuid references public.profiles(id),
 reviewed_at timestamptz,
 created_at timestamptz not null default now()
);
create index if not exists attendance_requests_student_idx on public.attendance_requests(student_id,created_at desc);
create index if not exists attendance_requests_class_idx on public.attendance_requests(class_id,review_status);
alter table public.attendance_requests enable row level security;
drop policy if exists "student reads own requests" on public.attendance_requests;
create policy "student reads own requests" on public.attendance_requests for select to authenticated
 using (student_id=(select auth.uid()));
drop policy if exists "assigned teacher reads requests" on public.attendance_requests;
create policy "assigned teacher reads requests" on public.attendance_requests for select to authenticated
 using (private.is_teacher_for_class(class_id));
drop policy if exists "student submits own pending requests" on public.attendance_requests;
create policy "student submits own pending requests" on public.attendance_requests for insert to authenticated
 with check (student_id=(select auth.uid()) and private.is_student_in_class(student_id,class_id) and review_status='pending' and reviewed_by is null and reviewed_at is null);
drop policy if exists "assigned teacher reviews requests" on public.attendance_requests;
create policy "assigned teacher reviews requests" on public.attendance_requests for update to authenticated
 using (private.is_teacher_for_class(class_id))
 with check (private.is_teacher_for_class(class_id));
-- Do not add public/anon policies. Student cannot update review status.
