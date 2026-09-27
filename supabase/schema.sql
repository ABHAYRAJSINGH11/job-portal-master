-- ============================================================
-- Job Portal — Supabase schema
-- ============================================================

-- ---------- TABLES ----------

create table if not exists companies (
  id         bigint generated always as identity primary key,
  created_at timestamptz not null default now(),
  name       text not null,
  logo_url   text
);

create table if not exists jobs (
  id           bigint generated always as identity primary key,
  created_at   timestamptz not null default now(),
  title        text not null,
  description  text not null,
  location     text not null,
  requirements text,
  "isOpen"     boolean not null default true,
  company_id   bigint references companies(id) on delete cascade,
  recruiter_id text not null  -- Clerk user id of whoever posted the job
);

create table if not exists saved_jobs (
  id         bigint generated always as identity primary key,
  created_at timestamptz not null default now(),
  job_id     bigint references jobs(id) on delete cascade,
  user_id    text not null   -- Clerk user id of the candidate who saved it
);

create table if not exists applications (
  id           bigint generated always as identity primary key,
  created_at   timestamptz not null default now(),
  job_id       bigint references jobs(id) on delete cascade,
  candidate_id text not null,  -- Clerk user id of the applicant
  name         text,
  status       text not null default 'applied',
  resume       text,
  skills       text,
  experience   integer,
  education    text
);

-- ---------- ROW LEVEL SECURITY ----------
-- These policies use auth.jwt()->>'sub', which is the Clerk user id,
-- once Clerk is connected as a Supabase Third-Party Auth provider.

alter table companies    enable row level security;
alter table jobs         enable row level security;
alter table saved_jobs   enable row level security;
alter table applications enable row level security;

-- Companies: anyone signed in can view; any signed-in user can add one
-- (matches the "add company" flow in post-job).
create policy "companies_select" on companies
  for select using (auth.jwt() is not null);

create policy "companies_insert" on companies
  for insert with check (auth.jwt() is not null);

-- Jobs: anyone signed in can browse; only the recruiter who owns a job
-- can update/close or delete it; any signed-in user can post a job.
create policy "jobs_select" on jobs
  for select using (auth.jwt() is not null);

create policy "jobs_insert" on jobs
  for insert with check (recruiter_id = auth.jwt()->>'sub');

create policy "jobs_update" on jobs
  for update using (recruiter_id = auth.jwt()->>'sub');

create policy "jobs_delete" on jobs
  for delete using (recruiter_id = auth.jwt()->>'sub');

-- Saved jobs: a user can only see/add/remove their own saved jobs.
create policy "saved_jobs_select" on saved_jobs
  for select using (user_id = auth.jwt()->>'sub');

create policy "saved_jobs_insert" on saved_jobs
  for insert with check (user_id = auth.jwt()->>'sub');

create policy "saved_jobs_delete" on saved_jobs
  for delete using (user_id = auth.jwt()->>'sub');

-- Applications: a candidate can insert/view their own applications;
-- a recruiter can view/update applications to jobs they posted.
create policy "applications_select" on applications
  for select using (
    candidate_id = auth.jwt()->>'sub'
    or exists (
      select 1 from jobs
      where jobs.id = applications.job_id
        and jobs.recruiter_id = auth.jwt()->>'sub'
    )
  );

create policy "applications_insert" on applications
  for insert with check (candidate_id = auth.jwt()->>'sub');

create policy "applications_update" on applications
  for update using (
    exists (
      select 1 from jobs
      where jobs.id = applications.job_id
        and jobs.recruiter_id = auth.jwt()->>'sub'
    )
  );

-- ---------- STORAGE BUCKETS ----------
-- Create two PUBLIC buckets (the app builds public URLs directly, so
-- both need public read access). Easiest to do this in the Dashboard:
--   Storage > New bucket > name "company-logo" > Public bucket: ON
--   Storage > New bucket > name "resumes"      > Public bucket: ON
-- Or via SQL:

insert into storage.buckets (id, name, public)
values ('company-logo', 'company-logo', true)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('resumes', 'resumes', true)
on conflict (id) do nothing;

-- Allow any signed-in user to upload to these buckets.
create policy "company_logo_upload" on storage.objects
  for insert with check (bucket_id = 'company-logo' and auth.jwt() is not null);

create policy "resumes_upload" on storage.objects
  for insert with check (bucket_id = 'resumes' and auth.jwt() is not null);

-- Public read (needed since the app links directly to the file URL).
create policy "company_logo_read" on storage.objects
  for select using (bucket_id = 'company-logo');

create policy "resumes_read" on storage.objects
  for select using (bucket_id = 'resumes');
