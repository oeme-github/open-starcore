-- Optionaler Einleitungstext im Viewer-Header (open-starcore_D08)
--
-- Nutzerwunsch: wie in der ursprünglichen Prozesskarte soll der Viewer unter
-- der Überschrift einen kurzen, immer sichtbaren Einordnungssatz und darunter
-- einen aufklappbaren Kasten mit ausführlicherem Text zeigen können — pro
-- Workgroup optional (alle drei Felder null = nichts anzeigen).
--
-- Pflege durch admin im Editor. workgroups hat bewusst KEINE Schreib-Policy
-- über PostgREST (Key/Name bleiben Sache des Betreibers, siehe
-- supabase/README.md "Erste Workgroup anlegen"). Statt einer allgemeinen
-- UPDATE-Policy, die dann auch key/name freigäbe, gibt es deshalb eine eng
-- begrenzte security-definer-Funktion, die ausschließlich die drei neuen
-- Spalten schreibt und die admin-Rolle selbst prüft — gleiches Muster wie
-- lookup_user_by_email/list_workgroup_members (Migration 20260719100000).
-- Lesen läuft über die bestehende Policy "Mitglieder sehen ihre Arbeitsgruppe".

alter table workgroups add column einleitung_kurz  text;
alter table workgroups add column einleitung_titel text;
alter table workgroups add column einleitung_text  text;

comment on column workgroups.einleitung_kurz is
  'Optional: kurzer Einordnungssatz, im Viewer immer sichtbar unter der Überschrift (auch im Druck).';
comment on column workgroups.einleitung_titel is
  'Optional: Überschrift des aufklappbaren Kastens im Viewer-Header (Default im Viewer: "Mehr erfahren").';
comment on column workgroups.einleitung_text is
  'Optional: Inhalt des aufklappbaren Kastens. Leerzeile = neuer Absatz, **fett** für Hervorhebungen; kein HTML (Viewer escaped alles).';

create or replace function public.set_workgroup_einleitung(
  p_workgroup_id uuid,
  p_kurz  text,
  p_titel text,
  p_text  text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not has_workgroup_role(p_workgroup_id, 'admin') then
    raise exception 'insufficient_privilege' using errcode = '42501';
  end if;
  update workgroups
     set einleitung_kurz  = nullif(btrim(p_kurz), ''),
         einleitung_titel = nullif(btrim(p_titel), ''),
         einleitung_text  = nullif(btrim(p_text), '')
   where id = p_workgroup_id;
end;
$$;

comment on function public.set_workgroup_einleitung is
  'Für admin: setzt den optionalen Einleitungstext (Einzeiler, Kasten-Überschrift, Kasten-Text) der Workgroup. Leere Strings werden zu null. Schreibt bewusst nur diese drei Spalten, nicht key/name.';

revoke execute on function public.set_workgroup_einleitung(uuid, text, text, text) from public;
grant execute on function public.set_workgroup_einleitung(uuid, text, text, text) to authenticated;
