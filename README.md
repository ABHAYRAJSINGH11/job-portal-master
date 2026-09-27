# Hirrd — Job Portal

A full-stack job portal where recruiters can post jobs and candidates can browse, save, and apply to them — built with React, Supabase, and Clerk.

**Live demo:** https://job-portal-master-37sg.vercel.app

## Features

- 🔐 Authentication with role selection (Candidate / Recruiter) via Clerk
- 📋 Recruiters can post jobs, add companies (with logo upload), and manage hiring status
- 🔍 Candidates can search and filter jobs by title, location, and company
- ❤️ Save jobs for later
- 📄 Apply to jobs with resume upload (PDF/Word), experience, skills, and education
- 📊 Recruiters can review applicants and update application status (Applied / Interviewing / Hired / Rejected)
- 🌓 Dark/light theme support

## Tech stack

| Layer          | Technology                                  |
| -------------- | -------------------------------------------- |
| Frontend       | React 18, Vite, React Router                 |
| Styling        | Tailwind CSS, shadcn/ui, Radix UI            |
| Forms          | React Hook Form, Zod                         |
| Auth           | Clerk (third-party auth provider)            |
| Database       | Supabase (PostgreSQL)                        |
| File storage   | Supabase Storage (company logos, resumes)    |
| Deployment     | Vercel                                       |

## Project structure

```
src/
├── api/            # Supabase queries (jobs, companies, applications)
├── components/     # UI components (job cards, forms, drawers, etc.)
├── components/ui/  # shadcn/ui primitives
├── hooks/          # useFetch — wraps API calls with Clerk session token
├── layouts/        # App shell / layout
├── pages/          # Route-level pages
└── utils/          # Supabase client setup
supabase/
└── schema.sql      # Database schema, RLS policies, storage buckets
```

## Getting started locally

### 1. Clone and install

```bash
git clone https://github.com/ABHAYRAJSINGH11/job-portal-master.git
cd job-portal-master
npm install
```

### 2. Set up Supabase

1. Create a project at [supabase.com](https://supabase.com).
2. In the SQL Editor, run `supabase/schema.sql` — this creates the `companies`, `jobs`, `saved_jobs`, and `applications` tables, their Row Level Security policies, and the `company-logo` / `resumes` storage buckets.
3. From **Project Settings → API**, copy the **Project URL** and **anon/publishable key**.

### 3. Set up Clerk

1. Create an application at [clerk.com](https://clerk.com).
2. Copy the **Publishable key** from API Keys.
3. Go to [dashboard.clerk.com/setup/supabase](https://dashboard.clerk.com/setup/supabase) and activate the Supabase integration for your app. Copy the Clerk domain it gives you.
4. In Supabase: **Authentication → Sign In / Up → Add provider → Clerk**, paste in that domain.
5. In Clerk: **Sessions → Edit → Customize session token**, add:
   ```json
   { "role": "authenticated" }
   ```

### 4. Environment variables

Create a `.env` file in the project root:

```
VITE_SUPABASE_URL=your-supabase-project-url
VITE_SUPABASE_ANON_KEY=your-supabase-anon-key
VITE_CLERK_PUBLISHABLE_KEY=your-clerk-publishable-key
```

### 5. Run

```bash
npm run dev
```

## Deployment (Vercel)

1. Import the repo into Vercel.
2. Add the same three environment variables under **Project → Settings → Environment Variables**.
3. In Clerk, add your Vercel domain under **Configure → Domains** so sign-in works on the live site.
4. Deploy — `vercel.json` already handles SPA routing (all routes rewrite to `index.html`).

## Notes

- Roles (Candidate/Recruiter) are stored on the Clerk user's `unsafeMetadata`, not in the database.
- Auth uses Clerk's native Supabase third-party integration (no JWT template / shared signing secret required).
- RLS policies scope job/application/saved-job access to the Clerk user id (`auth.jwt()->>'sub'`).
