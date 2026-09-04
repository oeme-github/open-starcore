-- Generischer Viewer-Filter für Nicht-Navigations-Dimensionen
--
-- Bisher bekommt nur ist_navigationsachse=true eine interaktive Filter-UI im
-- Viewer (Tab-Leiste/Toggle-Chips); alle anderen Dimensionen erscheinen nur
-- als statische Chips auf der Karte, ohne Filtermöglichkeit. Analog zu
-- ist_navigationsachse wird das jetzt als eigenes, unabhängiges Opt-in-Flag
-- pro Dimension pflegbar (Editor: "Dimensionen"-Verwaltung), statt es an
-- ist_navigationsachse zu koppeln oder pauschal für alle Dimensionen
-- einzuschalten. Nur für single_select/multi_select sinnvoll (text bleibt
-- über die Freitextsuche abgedeckt) — das wird clientseitig erzwungen, nicht
-- per DB-Constraint (Konsistenz mit ist_navigationsachse, das ebenfalls kein
-- CHECK gegen typ hat).

alter table dimensions add column ist_filterbar boolean not null default false;

comment on column dimensions.ist_filterbar is
  'Opt-in: Dimension bekommt im Viewer eine eigene interaktive Filterzeile in der Toolbar (Tab-Leiste bei single_select, Toggle-Chips bei multi_select), unabhängig von ist_navigationsachse. Nur für single_select/multi_select vorgesehen, bei typ=text im Editor ausgeblendet.';
