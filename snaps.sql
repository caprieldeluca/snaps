----------
-- Agregar vertices en intersecciones de poligonos de una tabla
----------
-- Se ordenan los polígonos de mayor a menor área,
--  para que tengan precedencia sus vértices. (Verificar esto)
-- Se fijan los vértices de las geometrías originales a una grilla,
--  luego se calclan las intersecciones (todos contra todos),
--  se extraen los vértices de las intersecciones, se hace el Snap
--  de los polígonos grillados a los vértices de las intersecciones y
--  por último se vuelven a llevar grillar los resultados. Tener en
--  cuenta los casos en los que las intersecciones caen lejos de 
--  un nodo de grilla.

WITH areas AS ( 
 SELECT
  -- Modificar el primer 'id' con nombre del atributo identificador
  id AS id,
  ST_Area(geometry) AS area,
  3 As prec, -- Precisión en las coordenadas (grilla)
  geometry AS geometry
 FROM
  -- Modificar 'poligonos' con nombre de la capa original
  'poligonos'
 ORDER BY area DESC
),
grillados AS (
 SELECT
  id,
  prec,
  ST_SnapToGrid(
   geometry,
   prec) AS geometry
 FROM
  areas
),
intersecciones AS (
 SELECT
  ST_SnapToGrid(
   ST_Intersection(g1.geometry, g2.geometry),
   g1.prec) AS geometry
 FROM
  grillados AS g1
  JOIN
  grillados AS g2
  ON
   -- Primero filtrar por intersección de rectángulos (es más rápido)
   MbrIntersects(g1.geometry, g2.geometry)
   AND ST_Intersects(g1.geometry, g2.geometry)
),
vertices AS (
 SELECT
  ST_DissolvePoints(geometry) AS geometry
 FROM
  intersecciones
),
filtrados AS (
SELECT
 RemoveRepeatedPoints(
  ST_Collect(geometry)) AS geometry 
FROM vertices
)
SELECT
 a.id,
 a.area,
 ST_SnapToGrid(
  ST_Snap(a.geometry, f.geometry, a.prec),
  a.prec) AS geometry
FROM
 areas AS a,
 filtrados AS f;
