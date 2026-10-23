create extension if not exists pgcrypto;

create type public.workspace_role as enum ('owner','admin','editor','viewer');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique check (username is null or username ~ '^[a-zA-Z0-9_]{3,32}$'),
  display_name text not null default '', avatar_url text,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.workspaces (
  id uuid primary key default gen_random_uuid(), name text not null check (char_length(trim(name)) between 1 and 80),
  description text not null default '', icon text, created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.workspace_members (
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role public.workspace_role not null default 'viewer', joined_at timestamptz not null default now(),
  primary key (workspace_id,user_id)
);
create table public.pages (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references public.workspaces(id) on delete cascade,
  parent_page_id uuid, title text not null default 'Untitled' check (char_length(title) between 1 and 200), content text not null default '', icon text,
  position numeric not null default 0, created_by uuid not null references auth.users(id), updated_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  constraint pages_parent_same_workspace foreign key (parent_page_id,workspace_id) references public.pages(id,workspace_id) on delete cascade,
  unique(id,workspace_id)
);
create table public.workspace_invitations (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references public.workspaces(id) on delete cascade,
  email text not null, role public.workspace_role not null check (role <> 'owner'), token_hash text not null unique,
  invited_by uuid not null references auth.users(id), expires_at timestamptz not null, accepted_at timestamptz, revoked_at timestamptz,
  created_at timestamptz not null default now()
);
create index pages_workspace_idx on public.pages(workspace_id,position);
create index invitations_workspace_idx on public.workspace_invitations(workspace_id,email);

create or replace function public.touch_updated_at() returns trigger language plpgsql set search_path=public as $$ begin new.updated_at=now(); return new; end $$;
create trigger profiles_touch before update on public.profiles for each row execute function public.touch_updated_at();
create trigger workspaces_touch before update on public.workspaces for each row execute function public.touch_updated_at();
create or replace function public.touch_page() returns trigger language plpgsql set search_path=public as $$ begin new.updated_at=now(); new.updated_by=auth.uid(); return new; end $$;
create trigger pages_touch before update on public.pages for each row execute function public.touch_page();
create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path=public as $$ begin insert into public.profiles(id,display_name) values(new.id,coalesce(new.raw_user_meta_data->>'display_name','')); return new; end $$;
create trigger on_auth_user_created after insert on auth.users for each row execute function public.handle_new_user();
create or replace function public.is_workspace_member(wid uuid) returns boolean language sql stable security definer set search_path=public as $$ select exists(select 1 from public.workspace_members where workspace_id=wid and user_id=auth.uid()) $$;
create or replace function public.workspace_role(wid uuid) returns public.workspace_role language sql stable security definer set search_path=public as $$ select role from public.workspace_members where workspace_id=wid and user_id=auth.uid() $$;
create or replace function public.create_workspace(p_name text,p_description text default '') returns public.workspaces language plpgsql security definer set search_path=public as $$ declare w public.workspaces; begin if auth.uid() is null then raise exception 'not authenticated'; end if; insert into public.workspaces(name,description,created_by) values(trim(p_name),coalesce(p_description,''),auth.uid()) returning * into w; insert into public.workspace_members(workspace_id,user_id,role) values(w.id,auth.uid(),'owner'); return w; end $$;
create or replace function public.create_page(p_workspace_id uuid,p_parent_page_id uuid,p_title text default 'Untitled') returns public.pages language plpgsql security invoker set search_path=public as $$ declare p public.pages; begin if public.workspace_role(p_workspace_id) not in ('owner','admin','editor') then raise exception 'insufficient permissions'; end if; insert into public.pages(workspace_id,parent_page_id,title,created_by,updated_by,position) values(p_workspace_id,p_parent_page_id,coalesce(nullif(trim(p_title),''),'Untitled'),auth.uid(),auth.uid(),coalesce((select max(position)+1 from public.pages where workspace_id=p_workspace_id and parent_page_id is not distinct from p_parent_page_id),0)) returning * into p; return p; end $$;
create or replace function public.create_workspace_invitation(p_workspace_id uuid,p_email text,p_role public.workspace_role) returns json language plpgsql security definer set search_path=public as $$ declare raw text; h text; i public.workspace_invitations; begin if public.workspace_role(p_workspace_id) not in ('owner','admin') then raise exception 'insufficient permissions'; end if; if p_role='owner' then raise exception 'owner invitations are not allowed'; end if; raw=encode(gen_random_bytes(32),'hex'); h=encode(digest(raw,'sha256'),'hex'); insert into public.workspace_invitations(workspace_id,email,role,token_hash,invited_by,expires_at) values(p_workspace_id,lower(trim(p_email)),p_role,h,auth.uid(),now()+interval '7 days') returning * into i; return json_build_object('id',i.id,'email',i.email,'role',i.role,'expires_at',i.expires_at,'token',raw); end $$;
create or replace function public.accept_workspace_invitation(p_token text) returns public.workspace_members language plpgsql security definer set search_path=public as $$ declare i public.workspace_invitations; m public.workspace_members; begin if auth.uid() is null then raise exception 'not authenticated'; end if; select * into i from public.workspace_invitations where token_hash=encode(digest(p_token,'sha256'),'hex') and accepted_at is null and revoked_at is null and expires_at>now() for update; if not found then raise exception 'invitation is invalid, expired, or revoked'; end if; if lower((select email from auth.users where id=auth.uid()))<>lower(i.email) then raise exception 'invitation email does not match signed-in user'; end if; insert into public.workspace_members(workspace_id,user_id,role) values(i.workspace_id,auth.uid(),i.role) on conflict (workspace_id,user_id) do nothing returning * into m; update public.workspace_invitations set accepted_at=now() where id=i.id; return m; end $$;

alter table public.profiles enable row level security; alter table public.workspaces enable row level security; alter table public.workspace_members enable row level security; alter table public.pages enable row level security; alter table public.workspace_invitations enable row level security;
create policy profiles_self on public.profiles for all using (id=auth.uid()) with check (id=auth.uid());
create policy workspace_member_read on public.workspaces for select using (public.is_workspace_member(id));
create policy workspace_owner_update on public.workspaces for update using (public.workspace_role(id) in ('owner','admin')) with check (public.workspace_role(id) in ('owner','admin'));
create policy workspace_owner_delete on public.workspaces for delete using (public.workspace_role(id)='owner');
create policy membership_read on public.workspace_members for select using (public.is_workspace_member(workspace_id));
create policy membership_admin_update on public.workspace_members for update using (public.workspace_role(workspace_id) in ('owner','admin') and role<>'owner') with check (role<>'owner');
create policy membership_admin_delete on public.workspace_members for delete using (public.workspace_role(workspace_id) in ('owner','admin') and role<>'owner');
create policy pages_read on public.pages for select using (public.is_workspace_member(workspace_id));
create policy pages_write on public.pages for insert with check (public.workspace_role(workspace_id) in ('owner','admin','editor') and created_by=auth.uid() and updated_by=auth.uid());
create policy pages_update on public.pages for update using (public.workspace_role(workspace_id) in ('owner','admin','editor')) with check (public.workspace_role(workspace_id) in ('owner','admin','editor') and updated_by=auth.uid());
create policy pages_delete on public.pages for delete using (public.workspace_role(workspace_id) in ('owner','admin','editor'));
create policy invitations_admin_read on public.workspace_invitations for select using (public.workspace_role(workspace_id) in ('owner','admin'));
revoke all on function public.create_workspace(text,text) from public; grant execute on function public.create_workspace(text,text) to authenticated;
revoke all on function public.create_workspace_invitation(uuid,text,public.workspace_role) from public; grant execute on function public.create_workspace_invitation(uuid,text,public.workspace_role) to authenticated;
revoke all on function public.accept_workspace_invitation(text) from public; grant execute on function public.accept_workspace_invitation(text) to authenticated;
revoke all on function public.create_page(uuid,uuid,text) from public; grant execute on function public.create_page(uuid,uuid,text) to authenticated;
