-- Optionale Erläuterung (Mouse-Over-Text) für Dimensionen und Dimension-Werte
--
-- Nutzerwunsch open-starcore_D07: einzelne Dimensionen (z.B. "Operation") und
-- einzelne Werte (z.B. "E" = Erzeugt) sollen im Viewer beim Überfahren mit der
-- Maus eine kurze Erklärung zeigen. Bewusst optional (null = kein Tooltip),
-- damit nur die Dimensionen/Werte betroffen sind, bei denen eine Workgroup
-- tatsächlich etwas einträgt. Keine neue RLS-Policy nötig — die bestehenden
-- Policies auf dimensions/dimension_values gelten zeilenweise, also auch für
-- die neue Spalte (Lesen ab viewer, Schreiben wie bisher admin bzw.
-- editor/admin für Werte).

alter table dimensions add column erlaeuterung text;
alter table dimension_values add column erlaeuterung text;

comment on column dimensions.erlaeuterung is
  'Optionaler Erklärtext zur Dimension, im Viewer als Mouse-Over (title) an Filterzeilen-/Detail-Beschriftung und Matrix-Achsen. null/leer = kein Tooltip.';
comment on column dimension_values.erlaeuterung is
  'Optionaler Erklärtext zum Wert, im Viewer als Mouse-Over (title) an Tabs, Filter-Chips, Karten-Chips/-Badges und Matrix-Köpfen. null/leer = kein Tooltip.';
