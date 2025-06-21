-- Script para corregir la asignación del micro a la ruta
-- Problema: El micro ABC123 no está asignado a ninguna ruta
-- Solución: Asignar el micro a la Ruta B

-- Verificar estado actual
SELECT 
    m.id as micro_id,
    m.placa,
    m.id_ruta as ruta_actual,
    r.nombre as nombre_ruta
FROM micro m
LEFT JOIN ruta r ON m.id_ruta = r.id
WHERE m.placa = 'ABC123';

-- Mostrar la ruta objetivo
SELECT id, nombre, descripcion 
FROM ruta 
WHERE nombre LIKE '%Ruta B%' OR id = 'f206dc92-2a2f-4bcf-9a6e-799d6b83033d';

-- ACTUALIZAR: Asignar el micro ABC123 a la Ruta B
UPDATE micro 
SET 
    id_ruta = 'f206dc92-2a2f-4bcf-9a6e-799d6b83033d',
    updated_at = NOW()
WHERE id = 'b9dcd6a8-a054-47c1-98a6-9c9dadbc6a2a';

-- Verificar que se aplicó correctamente
SELECT 
    m.id as micro_id,
    m.placa,
    m.id_ruta as ruta_asignada,
    r.nombre as nombre_ruta,
    m.updated_at
FROM micro m
LEFT JOIN ruta r ON m.id_ruta = r.id
WHERE m.placa = 'ABC123';

-- Mostrar todos los micros de la ruta para verificar
SELECT 
    m.id,
    m.placa,
    m.color,
    m.estado,
    r.nombre as ruta
FROM micro m
INNER JOIN ruta r ON m.id_ruta = r.id
WHERE r.id = 'f206dc92-2a2f-4bcf-9a6e-799d6b83033d'; 