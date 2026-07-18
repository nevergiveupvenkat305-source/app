-- Auto-create a profile row whenever a new auth user signs up (e.g. after
-- phone OTP verification), so the app never has to worry about a missing
-- profile. Defaults to the 'member' role; RoleSelectPage lets the user
-- change it post-signup via profiles_update_self_or_admin.

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, name, mobile, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'name', 'New Member'),
    new.phone,
    coalesce(new.raw_user_meta_data ->> 'role', 'member')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
