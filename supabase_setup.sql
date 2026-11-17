-- supabase_setup.sql
-- Cole TUDO no Supabase: SQL Editor > New query > Run.

-- 1) Tabela de perfis (1 linha por usuario cadastrado)
create table if not exists public.perfil (
  id               uuid primary key references auth.users(id) on delete cascade,
  nome             text not null default '',
  email            text,
  telefone         text,
  data_nascimento  text,
  cidade           text,
  papel            text not null default 'paciente'
                   check (papel in ('paciente', 'nutricionista')),
  criado_em        timestamptz not null default now()
);

-- 2) Seguranca (RLS): cada pessoa so enxerga e edita o proprio perfil
alter table public.perfil enable row level security;

drop policy if exists "ver proprio perfil" on public.perfil;
create policy "ver proprio perfil" on public.perfil
  for select to authenticated using (id = auth.uid());

drop policy if exists "editar proprio perfil" on public.perfil;
create policy "editar proprio perfil" on public.perfil
  for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

-- O usuario so pode alterar estes campos (nao pode mudar o proprio "papel")
revoke update on public.perfil from authenticated;
grant update (nome, telefone, data_nascimento, cidade) on public.perfil to authenticated;

-- 3) Cria o perfil automaticamente quando alguem se cadastra
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.perfil (id, nome, email, telefone, data_nascimento, cidade, papel)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'nome', ''),
    new.email,
    new.raw_user_meta_data->>'telefone',
    new.raw_user_meta_data->>'data_nascimento',
    new.raw_user_meta_data->>'cidade',
    case when new.raw_user_meta_data->>'papel' = 'nutricionista'
         then 'nutricionista' else 'paciente' end
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
