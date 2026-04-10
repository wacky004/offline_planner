-- ============================================================
-- Supabase Database Schema for Offline Planner App
-- Run this in your Supabase dashboard → SQL Editor
--
-- Row Level Security (RLS) ensures users can only access
-- their own rows.  All tables use user_id as a foreign key
-- to auth.users(id).
-- ============================================================

-- Enable UUID extension (usually already enabled on Supabase)
create extension if not exists "uuid-ossp";

-- ─── planner_entries ────────────────────────────────────────
create table if not exists planner_entries (
  id            text        primary key,
  user_id       uuid        not null references auth.users(id) on delete cascade,
  type          integer     not null,          -- EntryType.index
  title         text        not null,
  notes         text        not null default '',
  amount        double precision,
  date          timestamptz not null,
  is_completed_or_paid  boolean not null default false,
  has_reminder  boolean     not null default false,
  reminder_time timestamptz,
  alarm_sound_id text,
  updated_at    timestamptz not null default now()
);

alter table planner_entries enable row level security;

create policy "Users manage own entries" on planner_entries
  for all using (auth.uid() = user_id);

-- ─── goals ──────────────────────────────────────────────────
create table if not exists goals (
  id             text         primary key,
  user_id        uuid         not null references auth.users(id) on delete cascade,
  title          text         not null,
  target_amount  double precision not null,
  current_amount double precision not null default 0,
  updated_at     timestamptz  not null default now()
);

alter table goals enable row level security;

create policy "Users manage own goals" on goals
  for all using (auth.uid() = user_id);

-- ─── recipes ────────────────────────────────────────────────
create table if not exists recipes (
  id             text         primary key,
  user_id        uuid         not null references auth.users(id) on delete cascade,
  title          text         not null,
  ingredients    text         not null default '',
  cooking_steps  text         not null default '',
  category       integer      not null default 0,
  estimated_cost double precision,
  notes          text         not null default '',
  is_favorite    boolean      not null default false,
  created_at     timestamptz  not null default now(),
  updated_at     timestamptz  not null default now(),
  image_path     text,
  tags           text[]       not null default '{}'
);

alter table recipes enable row level security;

create policy "Users manage own recipes" on recipes
  for all using (auth.uid() = user_id);

-- ─── bible_books ─────────────────────────────────────────────
create table if not exists bible_books (
  id         text        primary key,
  user_id    uuid        not null references auth.users(id) on delete cascade,
  name       text        not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table bible_books enable row level security;

create policy "Users manage own bible_books" on bible_books
  for all using (auth.uid() = user_id);

-- ─── bible_chapters ──────────────────────────────────────────
create table if not exists bible_chapters (
  id            text        primary key,
  user_id       uuid        not null references auth.users(id) on delete cascade,
  book_id       text        not null,
  chapter_title text        not null,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

alter table bible_chapters enable row level security;

create policy "Users manage own bible_chapters" on bible_chapters
  for all using (auth.uid() = user_id);

-- ─── bible_verses ────────────────────────────────────────────
create table if not exists bible_verses (
  id           text        primary key,
  user_id      uuid        not null references auth.users(id) on delete cascade,
  book_id      text        not null,
  chapter_id   text        not null,
  verse_number integer     not null,
  verse_text   text        not null,
  note         text        not null default '',
  is_favorite  boolean     not null default false,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

alter table bible_verses enable row level security;

create policy "Users manage own bible_verses" on bible_verses
  for all using (auth.uid() = user_id);
