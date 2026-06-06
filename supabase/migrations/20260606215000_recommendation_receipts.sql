-- Store user-scoped SAV-E recommendation receipts for preference learning.
-- These are private telemetry receipts: user query, selected result metadata,
-- bounded reason snapshots, and derived preference signals. They do not expose
-- private saved-place memory to merchants or public place profiles.

create table if not exists public.recommendation_receipts (
    id uuid primary key default uuid_generate_v4(),
    user_id text references public.profiles(id) on delete cascade not null,
    query text not null,
    answer_source text not null default 'deterministic',
    answer_message text not null default '',
    selected_result_id text,
    selected_result_title text,
    result_snapshots jsonb not null default '[]'::jsonb,
    preference_signals jsonb not null default '[]'::jsonb,
    public_fallback_used boolean not null default false,
    created_at timestamptz not null default now()
);

alter table public.recommendation_receipts enable row level security;

create index if not exists idx_recommendation_receipts_user_created
    on public.recommendation_receipts(user_id, created_at desc);

create index if not exists idx_recommendation_receipts_preference_signals
    on public.recommendation_receipts using gin(preference_signals);

comment on table public.recommendation_receipts is
    'Private user-scoped recommendation receipts captured by save-api for preference learning and recommendation debugging.';
comment on column public.recommendation_receipts.result_snapshots is
    'Bounded visible result metadata and reasons shown to the user; not a public merchant feed.';
comment on column public.recommendation_receipts.preference_signals is
    'Derived private preference signals such as category, rating, saved-memory reason, or public quality signal.';
