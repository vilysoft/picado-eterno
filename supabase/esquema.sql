-- Picado Eterno · esquema de la base en Supabase
-- Correr una sola vez en el SQL Editor del proyecto (Project → SQL Editor → New query → Run).

-- 1) Una fila por partido terminado: sirve para estadísticas y balance.
create table if not exists public.partidas (
  id            bigint generated always as identity primary key,
  creado        timestamptz not null default now(),
  jugador       uuid,                       -- identificador al azar de cada navegador (no identifica a la persona)
  version       text,
  cancha        text not null check (cancha in ('potrero', 'club', 'lujo')),
  personaje     text not null check (personaje in ('diez', 'muro', 'arbitro', 'barra')),
  minuto        int  not null check (minuto between 0 and 120),
  ganado        boolean not null default false,
  alargue       boolean not null default false,
  nivel         int  not null check (nivel between 1 and 999),
  eliminados    int  not null check (eliminados between 0 and 1000000),
  jefes         int  not null default 0 check (jefes between 0 and 10),
  dano_recibido int  not null default 0,
  duracion_s    int  not null default 0,    -- segundos reales jugados
  celular       boolean not null default false,
  tecnicas      jsonb not null default '{}',  -- nivel de cada técnica al terminar
  fisicos       jsonb not null default '{}',  -- nivel de cada físico
  combos        jsonb not null default '[]',
  dano          jsonb not null default '{}'   -- daño total de cada técnica
);

-- 2) Una fila por marca subida al ranking (con apodo).
create table if not exists public.records (
  id          bigint generated always as identity primary key,
  creado      timestamptz not null default now(),
  apodo       text not null check (char_length(btrim(apodo)) between 1 and 16),
  cancha      text not null check (cancha in ('potrero', 'club', 'lujo')),
  personaje   text not null check (personaje in ('diez', 'muro', 'arbitro', 'barra')),
  minuto      int  not null check (minuto between 0 and 120),
  eliminados  int  not null check (eliminados between 0 and 1000000),
  nivel       int  not null check (nivel between 1 and 999),
  version     text
);

-- 3) Seguridad: el juego (rol anon) solo puede AGREGAR filas.
--    Las partidas no se pueden leer desde el juego; los récords sí (son públicos).
alter table public.partidas enable row level security;
alter table public.records  enable row level security;

drop policy if exists "el juego sube partidas" on public.partidas;
create policy "el juego sube partidas" on public.partidas for insert to anon with check (true);

drop policy if exists "el juego sube récords" on public.records;
create policy "el juego sube récords" on public.records for insert to anon with check (true);

drop policy if exists "los récords son públicos" on public.records;
create policy "los récords son públicos" on public.records for select to anon using (true);

-- 4) Ranking: la mejor marca de cada apodo en cada cancha.
create or replace view public.ranking with (security_invoker = true) as
select distinct on (cancha, lower(btrim(apodo)))
       cancha, btrim(apodo) as apodo, personaje, minuto, eliminados, nivel, creado
from public.records
order by cancha, lower(btrim(apodo)), minuto desc, eliminados desc, creado asc;

grant select on public.ranking to anon;

-- 5) Consultas útiles para balancear (correrlas en el SQL Editor cuando quieras):
-- Minuto promedio y % de victorias por cancha y personaje:
--   select cancha, personaje, count(*) partidas, round(avg(minuto)) minuto_prom,
--          round(100.0 * avg(ganado::int)) as pct_ganados
--   from partidas group by 1, 2 order by 1, 2;
-- Daño promedio de cada técnica:
--   select k as tecnica, round(avg(v::numeric)) dano_prom, count(*) veces
--   from partidas, jsonb_each_text(dano) as d(k, v) group by k order by dano_prom desc;
