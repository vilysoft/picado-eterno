-- Picado Eterno · migración del "Día de lluvia" (versión 2.70)
-- Correr una sola vez en el SQL Editor del proyecto. Se puede volver a correr sin problema.

-- 1) Marca si la partida o el récord se jugó con lluvia
alter table public.partidas add column if not exists lluvia boolean not null default false;
alter table public.records  add column if not exists lluvia boolean not null default false;

-- 2) El ranking de siempre queda solo con las marcas sin lluvia
create or replace view public.ranking with (security_invoker = true) as
select distinct on (cancha, lower(btrim(apodo)))
       cancha, btrim(apodo) as apodo, personaje, minuto, eliminados, nivel, creado
from public.records
where not lluvia
order by cancha, lower(btrim(apodo)), minuto desc, eliminados desc, creado asc;

-- 3) Ranking aparte para el día de lluvia
create or replace view public.ranking_lluvia with (security_invoker = true) as
select distinct on (cancha, lower(btrim(apodo)))
       cancha, btrim(apodo) as apodo, personaje, minuto, eliminados, nivel, creado
from public.records
where lluvia
order by cancha, lower(btrim(apodo)), minuto desc, eliminados desc, creado asc;

grant select on public.ranking to anon;
grant select on public.ranking_lluvia to anon;
