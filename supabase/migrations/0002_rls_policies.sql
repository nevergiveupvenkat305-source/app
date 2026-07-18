-- Row Level Security for every table in 0001_init_schema.sql.
-- Pattern: members act on their own rows / their own SHG's shared rows;
-- leader/crp/clf/admin roles get broader read (and, for leader, approval)
-- access; admin bypasses via the has_role() checks below.

-- ─────────────────────────────────────────────────────────────────────────
-- Helper functions (SECURITY DEFINER to avoid recursive RLS on profiles)
-- ─────────────────────────────────────────────────────────────────────────

create or replace function public.current_role()
returns text
language sql
security definer
stable
set search_path = public
as $$
  select role from public.profiles where id = auth.uid();
$$;

create or replace function public.current_shg_id()
returns uuid
language sql
security definer
stable
set search_path = public
as $$
  select shg_id from public.profiles where id = auth.uid();
$$;

create or replace function public.is_oversight_role()
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select public.current_role() in ('crp', 'clf', 'admin');
$$;

create or replace function public.is_leadership_role()
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select public.current_role() in ('leader', 'crp', 'clf', 'admin');
$$;

-- ─────────────────────────────────────────────────────────────────────────
-- profiles
-- ─────────────────────────────────────────────────────────────────────────

alter table public.profiles enable row level security;

create policy "profiles_select_self_or_shg_or_oversight"
  on public.profiles for select
  using (
    id = auth.uid()
    or shg_id = public.current_shg_id()
    or public.is_oversight_role()
  );

create policy "profiles_insert_self"
  on public.profiles for insert
  with check (id = auth.uid());

create policy "profiles_update_self_or_admin"
  on public.profiles for update
  using (id = auth.uid() or public.current_role() = 'admin');

-- ─────────────────────────────────────────────────────────────────────────
-- shgs
-- ─────────────────────────────────────────────────────────────────────────

alter table public.shgs enable row level security;

create policy "shgs_select_own_or_oversight"
  on public.shgs for select
  using (id = public.current_shg_id() or public.is_oversight_role());

create policy "shgs_write_leadership"
  on public.shgs for all
  using (id = public.current_shg_id() and public.is_leadership_role())
  with check (id = public.current_shg_id() and public.is_leadership_role());

-- ─────────────────────────────────────────────────────────────────────────
-- shg_documents
-- ─────────────────────────────────────────────────────────────────────────

alter table public.shg_documents enable row level security;

create policy "shg_documents_select"
  on public.shg_documents for select
  using (shg_id = public.current_shg_id() or public.is_oversight_role());

create policy "shg_documents_write_leadership"
  on public.shg_documents for all
  using (shg_id = public.current_shg_id() and public.is_leadership_role())
  with check (shg_id = public.current_shg_id() and public.is_leadership_role());

-- ─────────────────────────────────────────────────────────────────────────
-- savings_entries
-- ─────────────────────────────────────────────────────────────────────────

alter table public.savings_entries enable row level security;

create policy "savings_select_shg_or_oversight"
  on public.savings_entries for select
  using (shg_id = public.current_shg_id() or public.is_oversight_role());

create policy "savings_insert_own_or_leadership"
  on public.savings_entries for insert
  with check (
    shg_id = public.current_shg_id()
    and (member_id = auth.uid() or public.is_leadership_role())
  );

create policy "savings_update_leadership"
  on public.savings_entries for update
  using (shg_id = public.current_shg_id() and public.is_leadership_role());

-- ─────────────────────────────────────────────────────────────────────────
-- loans + loan_payments
-- ─────────────────────────────────────────────────────────────────────────

alter table public.loans enable row level security;

create policy "loans_select_shg_or_oversight"
  on public.loans for select
  using (shg_id = public.current_shg_id() or public.is_oversight_role());

create policy "loans_insert_own"
  on public.loans for insert
  with check (shg_id = public.current_shg_id() and member_id = auth.uid());

create policy "loans_update_leadership"
  on public.loans for update
  using (shg_id = public.current_shg_id() and public.is_leadership_role());

alter table public.loan_payments enable row level security;

create policy "loan_payments_select"
  on public.loan_payments for select
  using (
    exists (
      select 1 from public.loans l
      where l.id = loan_payments.loan_id
        and (l.shg_id = public.current_shg_id() or public.is_oversight_role())
    )
  );

create policy "loan_payments_insert"
  on public.loan_payments for insert
  with check (
    exists (
      select 1 from public.loans l
      where l.id = loan_payments.loan_id
        and l.shg_id = public.current_shg_id()
        and (l.member_id = auth.uid() or public.is_leadership_role())
    )
  );

-- ─────────────────────────────────────────────────────────────────────────
-- meetings, meeting_attendance, meeting_minutes, meeting_action_items
-- ─────────────────────────────────────────────────────────────────────────

alter table public.meetings enable row level security;

create policy "meetings_select"
  on public.meetings for select
  using (shg_id = public.current_shg_id() or public.is_oversight_role());

create policy "meetings_write_leadership"
  on public.meetings for all
  using (shg_id = public.current_shg_id() and public.is_leadership_role())
  with check (shg_id = public.current_shg_id() and public.is_leadership_role());

alter table public.meeting_attendance enable row level security;

create policy "attendance_select"
  on public.meeting_attendance for select
  using (
    exists (
      select 1 from public.meetings m
      where m.id = meeting_attendance.meeting_id
        and (m.shg_id = public.current_shg_id() or public.is_oversight_role())
    )
  );

create policy "attendance_write_leadership"
  on public.meeting_attendance for all
  using (
    exists (
      select 1 from public.meetings m
      where m.id = meeting_attendance.meeting_id
        and m.shg_id = public.current_shg_id()
        and public.is_leadership_role()
    )
  );

alter table public.meeting_minutes enable row level security;

create policy "minutes_select"
  on public.meeting_minutes for select
  using (
    exists (
      select 1 from public.meetings m
      where m.id = meeting_minutes.meeting_id
        and (m.shg_id = public.current_shg_id() or public.is_oversight_role())
    )
  );

create policy "minutes_write_leadership"
  on public.meeting_minutes for all
  using (
    exists (
      select 1 from public.meetings m
      where m.id = meeting_minutes.meeting_id
        and m.shg_id = public.current_shg_id()
        and public.is_leadership_role()
    )
  );

alter table public.meeting_action_items enable row level security;

create policy "action_items_select"
  on public.meeting_action_items for select
  using (
    exists (
      select 1 from public.meetings m
      where m.id = meeting_action_items.meeting_id
        and (m.shg_id = public.current_shg_id() or public.is_oversight_role())
    )
  );

create policy "action_items_write_leadership"
  on public.meeting_action_items for all
  using (
    exists (
      select 1 from public.meetings m
      where m.id = meeting_action_items.meeting_id
        and m.shg_id = public.current_shg_id()
        and public.is_leadership_role()
    )
  );

-- ─────────────────────────────────────────────────────────────────────────
-- financial_ledger
-- ─────────────────────────────────────────────────────────────────────────

alter table public.financial_ledger enable row level security;

create policy "ledger_select"
  on public.financial_ledger for select
  using (shg_id = public.current_shg_id() or public.is_oversight_role());

create policy "ledger_write_leadership"
  on public.financial_ledger for all
  using (shg_id = public.current_shg_id() and public.is_leadership_role())
  with check (shg_id = public.current_shg_id() and public.is_leadership_role());

-- ─────────────────────────────────────────────────────────────────────────
-- livelihood_activities
-- ─────────────────────────────────────────────────────────────────────────

alter table public.livelihood_activities enable row level security;

create policy "livelihood_select"
  on public.livelihood_activities for select
  using (shg_id = public.current_shg_id() or public.is_oversight_role());

create policy "livelihood_insert_own_or_leadership"
  on public.livelihood_activities for insert
  with check (
    shg_id = public.current_shg_id()
    and (member_id = auth.uid() or public.is_leadership_role())
  );

create policy "livelihood_update_own_or_leadership"
  on public.livelihood_activities for update
  using (
    shg_id = public.current_shg_id()
    and (member_id = auth.uid() or public.is_leadership_role())
  );

-- ─────────────────────────────────────────────────────────────────────────
-- marketplace_products, marketplace_orders, marketplace_reviews
-- ─────────────────────────────────────────────────────────────────────────

alter table public.marketplace_products enable row level security;

create policy "products_select_all"
  on public.marketplace_products for select
  using (true);

create policy "products_write_own"
  on public.marketplace_products for all
  using (seller_id = auth.uid())
  with check (seller_id = auth.uid());

alter table public.marketplace_orders enable row level security;

create policy "orders_select_seller_or_oversight"
  on public.marketplace_orders for select
  using (
    exists (
      select 1 from public.marketplace_products p
      where p.id = marketplace_orders.product_id and p.seller_id = auth.uid()
    )
    or public.is_oversight_role()
  );

create policy "orders_insert_any_authenticated"
  on public.marketplace_orders for insert
  with check (auth.uid() is not null);

create policy "orders_update_seller"
  on public.marketplace_orders for update
  using (
    exists (
      select 1 from public.marketplace_products p
      where p.id = marketplace_orders.product_id and p.seller_id = auth.uid()
    )
  );

alter table public.marketplace_reviews enable row level security;

create policy "reviews_select_all"
  on public.marketplace_reviews for select
  using (true);

create policy "reviews_insert_authenticated"
  on public.marketplace_reviews for insert
  with check (auth.uid() is not null);

-- ─────────────────────────────────────────────────────────────────────────
-- schemes, scheme_applications
-- ─────────────────────────────────────────────────────────────────────────

alter table public.schemes enable row level security;

create policy "schemes_select_all"
  on public.schemes for select
  using (true);

create policy "schemes_write_admin"
  on public.schemes for all
  using (public.current_role() = 'admin')
  with check (public.current_role() = 'admin');

alter table public.scheme_applications enable row level security;

create policy "scheme_apps_select_own_or_oversight"
  on public.scheme_applications for select
  using (member_id = auth.uid() or public.is_oversight_role());

create policy "scheme_apps_insert_own"
  on public.scheme_applications for insert
  with check (member_id = auth.uid());

create policy "scheme_apps_update_own_or_admin"
  on public.scheme_applications for update
  using (member_id = auth.uid() or public.current_role() = 'admin');

-- ─────────────────────────────────────────────────────────────────────────
-- training_courses, course_progress
-- ─────────────────────────────────────────────────────────────────────────

alter table public.training_courses enable row level security;

create policy "courses_select_all"
  on public.training_courses for select
  using (true);

create policy "courses_write_oversight"
  on public.training_courses for all
  using (public.is_oversight_role())
  with check (public.is_oversight_role());

alter table public.course_progress enable row level security;

create policy "progress_select_own_or_oversight"
  on public.course_progress for select
  using (member_id = auth.uid() or public.is_oversight_role());

create policy "progress_write_own"
  on public.course_progress for all
  using (member_id = auth.uid())
  with check (member_id = auth.uid());

-- ─────────────────────────────────────────────────────────────────────────
-- payments
-- ─────────────────────────────────────────────────────────────────────────

alter table public.payments enable row level security;

create policy "payments_select_own_or_oversight"
  on public.payments for select
  using (member_id = auth.uid() or public.is_oversight_role());

create policy "payments_insert_own"
  on public.payments for insert
  with check (member_id = auth.uid());

-- ─────────────────────────────────────────────────────────────────────────
-- announcements, announcement_reads
-- ─────────────────────────────────────────────────────────────────────────

alter table public.announcements enable row level security;

create policy "announcements_select"
  on public.announcements for select
  using (
    shg_id is null
    or shg_id = public.current_shg_id()
    or public.is_oversight_role()
  );

create policy "announcements_write_leadership"
  on public.announcements for all
  using (public.is_leadership_role())
  with check (public.is_leadership_role());

alter table public.announcement_reads enable row level security;

create policy "announcement_reads_own"
  on public.announcement_reads for all
  using (member_id = auth.uid())
  with check (member_id = auth.uid());

-- ─────────────────────────────────────────────────────────────────────────
-- support_tickets, support_messages
-- ─────────────────────────────────────────────────────────────────────────

alter table public.support_tickets enable row level security;

create policy "tickets_select_own_or_admin"
  on public.support_tickets for select
  using (member_id = auth.uid() or public.current_role() = 'admin');

create policy "tickets_insert_own"
  on public.support_tickets for insert
  with check (member_id = auth.uid());

create policy "tickets_update_own_or_admin"
  on public.support_tickets for update
  using (member_id = auth.uid() or public.current_role() = 'admin');

alter table public.support_messages enable row level security;

create policy "messages_select_own_ticket_or_admin"
  on public.support_messages for select
  using (
    exists (
      select 1 from public.support_tickets t
      where t.id = support_messages.ticket_id
        and (t.member_id = auth.uid() or public.current_role() = 'admin')
    )
  );

create policy "messages_insert_own_ticket_or_admin"
  on public.support_messages for insert
  with check (
    exists (
      select 1 from public.support_tickets t
      where t.id = support_messages.ticket_id
        and (t.member_id = auth.uid() or public.current_role() = 'admin')
    )
  );

-- ─────────────────────────────────────────────────────────────────────────
-- ai_advisor_logs
-- ─────────────────────────────────────────────────────────────────────────

alter table public.ai_advisor_logs enable row level security;

create policy "ai_logs_own"
  on public.ai_advisor_logs for all
  using (member_id = auth.uid())
  with check (member_id = auth.uid());

-- ─────────────────────────────────────────────────────────────────────────
-- report_snapshots, analytics_kpis (read-only for members/leadership,
-- written only by trusted server-side jobs using the service-role key)
-- ─────────────────────────────────────────────────────────────────────────

alter table public.report_snapshots enable row level security;

create policy "reports_select"
  on public.report_snapshots for select
  using (
    shg_id is null
    or shg_id = public.current_shg_id()
    or public.is_oversight_role()
  );

alter table public.analytics_kpis enable row level security;

create policy "analytics_select"
  on public.analytics_kpis for select
  using (
    shg_id is null
    or shg_id = public.current_shg_id()
    or public.is_oversight_role()
  );

-- ─────────────────────────────────────────────────────────────────────────
-- audit_log (admin only)
-- ─────────────────────────────────────────────────────────────────────────

alter table public.audit_log enable row level security;

create policy "audit_log_admin_only"
  on public.audit_log for select
  using (public.current_role() = 'admin');

create policy "audit_log_insert_any_authenticated"
  on public.audit_log for insert
  with check (auth.uid() is not null);
