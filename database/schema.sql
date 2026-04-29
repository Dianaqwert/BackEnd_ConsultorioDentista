-- Database: dentistaConsultorio

-- DROP DATABASE IF EXISTS "dentistaConsultorio";

CREATE DATABASE "dentistaConsultorio"
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'Spanish_Mexico.1252'
    LC_CTYPE = 'Spanish_Mexico.1252'
    LOCALE_PROVIDER = 'libc'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;

-- Database: dentistaConsultorio

CREATE EXTENSION IF NOT EXISTS unaccent;
-------------------------------------------------------------
-- TABLAS QUE NO DEPENDEN DE OTRAS
-------------------------------------------------------------

CREATE TABLE Usuario_Empleado (
    id_usuario SERIAL PRIMARY KEY,
    nombreUsuario VARCHAR(255) NOT NULL,
    nombres VARCHAR(255) NOT NULL,
    apellidoPat VARCHAR(255) NOT NULL,
    apellidoMat VARCHAR(255) NOT NULL,
    tipoEmpleado VARCHAR(60),
  	fecha_hora TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    contrasenaUE VARCHAR(60) NOT NULL,
    CONSTRAINT check_tipoEmpleado CHECK (tipoEmpleado IN ('Recepcion','Ayudante','Dentista'))
);

ALTER TABLE Usuario_Empleado
ADD COLUMN superAdmin BOOLEAN DEFAULT FALSE;

-- 1. Evitar que se repita el 'nombreUsuario' (Login)
ALTER TABLE Usuario_Empleado 
ADD CONSTRAINT uq_usuario_login UNIQUE (nombreUsuario);

-- 2. Evitar que se repita la misma PERSONA (Nombre + Apellidos)
ALTER TABLE Usuario_Empleado 
ADD CONSTRAINT uq_persona_fisica UNIQUE (nombres, apellidoPat, apellidoMat);

CREATE TABLE Metodo_Pago (
    id_metodo_pago SERIAL PRIMARY KEY,
    nombre_metodo VARCHAR(255) NOT NULL,
    CONSTRAINT check_metodoPago CHECK (nombre_metodo IN ('Efectivo','Transferencia'))
);

CREATE TABLE Tratamiento (
    id_tipo_tratamiento SERIAL PRIMARY KEY, 
    nombre VARCHAR(255) NOT NULL, 
    descripcion VARCHAR(255),
    costo INTEGER NOT NULL
);

ALTER TABLE Tratamiento
ADD COLUMN activo BOOLEAN DEFAULT TRUE;
select * from tratamiento

CREATE TABLE Tipo_Material (
    id_tipo_material SERIAL PRIMARY KEY,
    nombre_tipo VARCHAR(255)
);

-------------------------------------------------------------
-- TABLA PACIENTE
-------------------------------------------------------------

CREATE TABLE Paciente (
    id_paciente SERIAL PRIMARY KEY,
    nombresPaciente VARCHAR(100) NOT NULL,
    apellidoPat VARCHAR(100) NOT NULL,
    apellidoMat VARCHAR(100) NOT NULL,
    telefono VARCHAR(20) NOT NULL,
	fecha_hora TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    email VARCHAR(255) NOT NULL UNIQUE
);
ALTER TABLE Paciente
DROP CONSTRAINT IF EXISTS uq_paciente_telefono;

delete from paciente where id_paciente=22
select * from paciente

-------------------------------------------------------------
-- DIRECCIÓN (Relación 1–1 corregida)
-------------------------------------------------------------

CREATE TABLE Direccion (
    id_direccion SERIAL PRIMARY KEY,
    CP INTEGER,
    calle VARCHAR(100) NOT NULL,
    colonia VARCHAR(100) NOT NULL,
    municipio VARCHAR(100) NOT NULL,
    numeroInt INTEGER,
    numeroExt INTEGER,
    id_paciente INTEGER UNIQUE, -- Mantiene la relación 1–1
    CONSTRAINT fk_idPaciente FOREIGN KEY (id_paciente) REFERENCES Paciente(id_paciente)
);

select * from Direccion
-------------------------------------------------------------
-- DERIVACIÓN
-------------------------------------------------------------

CREATE TABLE Derivacion (
    id_derivacion SERIAL PRIMARY KEY,
    fecha DATE NOT NULL,
    nombreDentista VARCHAR(100) NOT NULL,
    motivo VARCHAR(255) NOT NULL,
    especialidadDentista VARCHAR(255),
    apellidoPatDentista VARCHAR(255),
    apellidoMatDentista VARCHAR(255),
    id_paciente INTEGER,
    CONSTRAINT fk_derivacionPaciente FOREIGN KEY (id_paciente) REFERENCES Paciente(id_paciente)
);
ALTER TABLE Derivacion
ADD COLUMN fecha_hora TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;
-------------------------------------------------------------
-- ESTUDIO
-------------------------------------------------------------

CREATE TABLE Estudio (
    id_tipoEstudio SERIAL PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL,
    descripcion VARCHAR(255),
    fecha DATE NOT NULL,
    resultados VARCHAR(255) NOT NULL,
    id_paciente INTEGER,
    CONSTRAINT fk_estudioPaciente FOREIGN KEY (id_paciente) REFERENCES Paciente(id_paciente)
);

-------------------------------------------------------------
-- CITA (corrección del nombre de la FK)
-------------------------------------------------------------

CREATE TABLE Cita (
    id_cita SERIAL PRIMARY KEY,
    fecha_hora DATE NOT NULL,
    descripcion VARCHAR(255),
    estado_cita VARCHAR(100),
    id_paciente INTEGER,
	hora TIME not null,

    CONSTRAINT check_estadoCita CHECK (estado_cita IN 
        ('Agendada','Confirmada','Cancelada','Pendiente','Reprogramada','Atendida','No asistio')),
    CONSTRAINT fk_citaPaciente FOREIGN KEY (id_paciente) REFERENCES Paciente(id_paciente)
);
select * from cita
-------------------------------------------------------------
-- HISTORIAL CLÍNICO
-------------------------------------------------------------

CREATE TABLE Historial_Clinico (
    id_historial SERIAL PRIMARY KEY,
    alergias VARCHAR(255),
    enfermedades VARCHAR(255) NOT NULL,
    avanceTratamiento VARCHAR(255),
    fecha DATE NOT NULL,
    id_cita INTEGER,
    CONSTRAINT fk_citaHistorial FOREIGN KEY (id_cita) REFERENCES Cita(id_cita)
);

-- Permitir que enfermedades sea NULL
ALTER TABLE Historial_Clinico
ALTER COLUMN enfermedades DROP NOT NULL;

-- Obligar a que avanceTratamiento NO sea NULL
ALTER TABLE Historial_Clinico
ALTER COLUMN avanceTratamiento SET NOT NULL;

-------------------------------------------------------------
-- USUARIO_EMPLEADOS_CITA (tabla N–M)
-------------------------------------------------------------

CREATE TABLE Usuario_Empleados_Cita (
    id_cita INTEGER,
    id_usuario INTEGER,
    tipo_empleado VARCHAR(255) NOT NULL,
    PRIMARY KEY (id_cita, id_usuario),
    CONSTRAINT check_tipoEmpleado_uec CHECK (tipo_empleado IN ('Recepcion','Ayudante','Dentista')),
    CONSTRAINT fk_empleadosCita FOREIGN KEY (id_cita) REFERENCES Cita(id_cita),
    CONSTRAINT fk_empleados_Usuario FOREIGN KEY (id_usuario) REFERENCES Usuario_Empleado(id_usuario)
);

-------------------------------------------------------------
-- DEUDA
-------------------------------------------------------------

CREATE TABLE Deuda (
    id_deuda SERIAL PRIMARY KEY,
    monto_pagado INTEGER,
    monto_total INTEGER,
    saldo_pendiente INTEGER,
    id_cita INTEGER,
    estado VARCHAR(255),
    CONSTRAINT check_estadoDeuda CHECK (estado IN ('Pendiente a pagar','Abono','Pagada')),
    CONSTRAINT fk_deuda_cita FOREIGN KEY (id_cita) REFERENCES Cita(id_cita)
);

-------------------------------------------------------------
-- PAGO
-------------------------------------------------------------

CREATE TABLE Pago (
    idPago SERIAL PRIMARY KEY,
    cantidadPagada INTEGER,
	fecha_hora TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    id_cita INTEGER,
    metodoPagoid_metodopago INTEGER,
    CONSTRAINT fk_pago_cita FOREIGN KEY (id_cita) REFERENCES Cita(id_cita),
    CONSTRAINT fk_pago_metodo FOREIGN KEY (metodoPagoid_metodopago) REFERENCES Metodo_Pago(id_metodo_pago)
);

-------------------------------------------------------------
-- DETALLE COSTO (relación con Pago restaurada)
-------------------------------------------------------------

CREATE TABLE Detalle_Costo (
    id_detalle SERIAL PRIMARY KEY,
    cantidad INTEGER,
    subTotal INTEGER,
    id_cita INTEGER,
    id_tipo_tratamiento INTEGER,
    id_tipo_material INTEGER,
    id_pago INTEGER,

    CONSTRAINT fk_detalle_cita 
        FOREIGN KEY (id_cita) REFERENCES Cita(id_cita),

    CONSTRAINT fk_detalle_trat 
        FOREIGN KEY (id_tipo_tratamiento) REFERENCES Tratamiento(id_tipo_tratamiento),

    CONSTRAINT fk_detalle_tipoMaterial 
        FOREIGN KEY (id_tipo_material) REFERENCES Tipo_Material(id_tipo_material),

    CONSTRAINT fk_detalle_pago
        FOREIGN KEY (id_pago) REFERENCES Pago(idPago)
);

-------------------------------------------------------------
-- MATERIAL TRATAMIENTO
-------------------------------------------------------------

CREATE TABLE Material_Tratamiento (
    id_material SERIAL PRIMARY KEY,
    nombre VARCHAR(255),
    costoUnitario INTEGER,
    stock INTEGER,
    cantidad INTEGER,
    id_tipo_material INTEGER,
    CONSTRAINT fk_materialTratamiento_tipoMaterial
        FOREIGN KEY (id_tipo_material) REFERENCES Tipo_Material(id_tipo_material)
);

--INSERTS
select * from usuario_empleado
INSERT INTO Usuario_Empleado (
    nombreUsuario, nombres, apellidoPat, apellidoMat, tipoEmpleado,contrasenaUE
) VALUES
('admin', 'Carlos', 'Gonzalez', 'Lopez', 'Recepcion', 'Admin123');

INSERT INTO Usuario_Empleado (
    nombreUsuario, nombres, apellidoPat, apellidoMat, tipoEmpleado, contrasenaUE
) VALUES
('jlopez', 'Juan', 'Lopez', 'Martinez', 'Dentista', 'ContraJuan01');

INSERT INTO Usuario_Empleado (
    nombreUsuario, nombres, apellidoPat, apellidoMat, tipoEmpleado, contrasenaUE
) VALUES
('marias', 'María', 'Sanchez', 'Rivas', 'Ayudante', 'MariaSecure22');

INSERT INTO Usuario_Empleado (
    nombreUsuario, nombres, apellidoPat, apellidoMat, tipoEmpleado, contrasenaUE
) VALUES
('diana', 'Diana', 'Sanchez', 'Rivas', 'Dentista', 'admin')

UPDATE Usuario_Empleado
SET superAdmin = TRUE
WHERE id_usuario = 4;

select * from Usuario_Empleado
-- MÉTODO DE PAGO
INSERT INTO Metodo_Pago (nombre_metodo) VALUES
('Efectivo'),
('Transferencia');

-- TRATAMIENTOS
INSERT INTO Tratamiento (nombre, descripcion, costo) VALUES
('Limpieza Dental', 'Limpieza profunda y eliminación de sarro', 500),
('Ortodoncia', 'Tratamiento de alineación dental', 1500),
('Extracción', 'Extracción de pieza dental', 800),
('Resina', 'Resina estética dental', 600),
('Blanqueamiento', 'Blanqueamiento dental profesional', 1200);

-- TIPO DE MATERIAL
INSERT INTO Tipo_Material (nombre_tipo) VALUES
('Anestesia'),
('Resina'),
('Material Ortodoncia'),
('Blanqueador'),
('Equipo General');

-- MATERIALES
INSERT INTO Material_Tratamiento (nombre, costoUnitario, stock, cantidad, id_tipo_material) VALUES
('Lidocaina', 50, 100, 1, 1),
('Resina Fotocurada', 80, 50, 1, 2),
('Bracket Metálico', 40, 200, 2, 3),
('Gel Blanqueador', 100, 30, 1, 4),
('Kit Limpieza', 30, 100, 1, 5);

----------------------------------------


-------------------------------------------------------
-- CATEGORÍA 1: ANESTESIA (ID 1)
-- Escenario: Materiales de uso diario, precios variados.
-------------------------------------------------------
INSERT INTO Material_Tratamiento (nombre, costoUnitario, stock, cantidad, id_tipo_material) VALUES
('Lidocaína con Epinefrina', 50, 150, 1, 1),       -- Normal
('Mepivacaína (Sin vaso)', 65, 80, 1, 1),          -- Normal
('Articaína 4% (Reforzada)', 85, 4, 1, 1),         -- CRÍTICO (Stock < 5)
('Benzocaína Tópica (Gel)', 120, 20, 1, 1),        -- Normal
('Agujas Cortas 30G (Caja)', 200, 5, 1, 1),        -- CRÍTICO (Stock <= 5)
('Agujas Largas 27G (Caja)', 200, 50, 1, 1),       -- Normal
('Jeringa Carpule Metálica', 450, 2, 1, 1);        -- CRÍTICO y Costoso (Activo fijo)

-------------------------------------------------------
-- CATEGORÍA 2: RESINA (ID 2)
-- Escenario: Categoría de "Alto Valor" (Mucho dinero invertido).
-------------------------------------------------------
INSERT INTO Material_Tratamiento (nombre, costoUnitario, stock, cantidad, id_tipo_material) VALUES
('Resina A1 (Estética)', 450, 20, 1, 2),           -- Caro
('Resina A2 (Universal)', 450, 100, 1, 2),         -- MUY ALTO VALOR (450 * 100 = $45,000)
('Resina A3 (Cuellos)', 450, 15, 1, 2),            -- Normal
('Resina Fluida Transparente', 380, 8, 1, 2),      -- BAJO (Stock < 10)
('Ácido Grabador 37%', 120, 0, 1, 2),              -- AGOTADO (Stock 0)
('Adhesivo Universal (Bond)', 950, 12, 1, 2),      -- Unitario muy caro
('Pinceles Aplicadores', 25, 200, 1, 2);           -- Barato, mucho stock (Baja el promedio)

-------------------------------------------------------
-- CATEGORÍA 3: MATERIAL ORTODONCIA (ID 3)
-- Escenario: Mezcla de consumibles baratos y piezas caras.
-------------------------------------------------------
INSERT INTO Material_Tratamiento (nombre, costoUnitario, stock, cantidad, id_tipo_material) VALUES
('Juego Brackets Metálicos', 300, 50, 1, 3),       -- Normal
('Juego Brackets Zafiro', 2500, 3, 1, 3),          -- CRÍTICO y CARÍSIMO
('Arcos NiTi 014 (Paq)', 150, 40, 1, 3),           -- Normal
('Arcos Acero Rectangular', 180, 25, 1, 3),        -- Normal
('Ligas de Colores (Paquete)', 15, 500, 1, 3),     -- Mucho stock, muy barato
('Cera de Ortodoncia', 20, 100, 1, 3),             -- Barato
('Tubos Molares Soldables', 80, 0, 1, 3),          -- AGOTADO
('Cadeneta Elástica', 120, 9, 1, 3);               -- BAJO

-------------------------------------------------------
-- CATEGORÍA 4: BLANQUEADOR (ID 4)
-- Escenario: Productos químicos perecederos.
-------------------------------------------------------
INSERT INTO Material_Tratamiento (nombre, costoUnitario, stock, cantidad, id_tipo_material) VALUES
('Kit Blanqueamiento Consultorio', 1500, 5, 1, 4), -- CRÍTICO y Alto Valor
('Jeringa Repuesto Peróxido', 400, 2, 1, 4),       -- CRÍTICO
('Barrera Gingival', 250, 15, 1, 4),               -- Normal
('Pasta Pulidora Diamantada', 350, 8, 1, 4),       -- BAJO
('Cubetas Termoformables', 50, 60, 1, 4),          -- Normal
('Desensibilizante Dental', 600, 4, 1, 4);         -- CRÍTICO

-------------------------------------------------------
-- CATEGORÍA 5: EQUIPO GENERAL / DESECHABLES (ID 5)
-- Escenario: Volumen alto, costo bajo (Consumibles masivos).
-------------------------------------------------------
INSERT INTO Material_Tratamiento (nombre, costoUnitario, stock, cantidad, id_tipo_material) VALUES
('Guantes Látex Medianos (Caja)', 180, 50, 1, 5),  -- Normal
('Guantes Nitrilo Chicos (Caja)', 220, 0, 1, 5),   -- AGOTADO
('Cubrebocas Tricapa (Paq)', 100, 200, 1, 5),      -- Mucho Stock
('Eyectores de Saliva', 45, 300, 1, 5),            -- Mucho Stock
('Baberos Desechables', 60, 150, 1, 5),            -- Normal
('Rollos de Algodón', 30, 8, 1, 5),                -- BAJO (Raro para algodón)
('Gasas Estériles 10x10', 80, 12, 1, 5);           -- Normal
--------------------------------------------

INSERT INTO Paciente (nombresPaciente, apellidoPat, apellidoMat, telefono,email) VALUES
('Álvaro', 'Hernández', 'Gómez', '4491234567', 'álvaro.hg@example.com'),
('María', 'López', 'Ramírez', '4492345678', 'maría.lr@example.com'),
('José', 'Martínez', 'Cárdenas', '4493456789', 'josé.mc@example.com'),
('Lucía', 'Fernández', 'Torres', '4494567890', 'lucía.ft@example.com'),
('Óscar', 'Rodríguez', 'Vázquez', '4495678901', 'óscar.rv@example.com'),
('Camila', 'Pérez', 'Núñez', '4496789012', 'camila.pn@example.com'),
('Estéban', 'García', 'Sánchez', '4497890123', 'estéban.gs@example.com');

INSERT INTO Paciente (nombresPaciente, apellidoPat, apellidoMat, telefono, email) VALUES
('Sofía', 'Ramírez', 'Delgado', '4498901234', 'sofía.rd@example.com'),
('Andrés', 'Castillo', 'Moreno', '4499012345', 'andrés.cm@example.com'),
('Valentina', 'Gutiérrez', 'Salinas', '4490123456', 'valentina.gs@example.com'),
('Diego', 'Vargas', 'Hernández', '4491234568', 'diego.vh@example.com'),
('Isabella', 'Flores', 'Martínez', '4492345679', 'isabella.fm@example.com'),
('Mateo', 'Cruz', 'Ortega', '4493456780', 'mateo.co@example.com'),
('Renata', 'Jiménez', 'Paredes', '4494567891', 'renata.jp@example.com'),
('Sebastián', 'Navarro', 'Quintero', '4495678902', 'sebastián.nq@example.com'),
('Paola', 'Domínguez', 'Ríos', '4496789013', 'paola.dr@example.com'),
('Fernando', 'Suárez', 'Treviño', '4497890124', 'fernando.st@example.com');

select * from paciente

ALTER TABLE Direccion
ALTER COLUMN numeroInt TYPE VARCHAR(10);

INSERT INTO Direccion (CP, calle, colonia, municipio, numeroInt, numeroExt, id_paciente) VALUES
('20010', 'Calle Encino', 'Col. Las Flores', 'Aguascalientes', '2A', '101', 1),
('20020', 'Avenida Hidalgo', 'Col. Centro', 'Aguascalientes', '3B', '202', 2),
('20030', 'Calle Olivo', 'Col. San Marcos', 'Aguascalientes', '1C', '303', 3),
('20040', 'Boulevard Zacatecas', 'Col. Industrial', 'Aguascalientes', '4D', '404', 4),
('20050', 'Calle Magnolia', 'Col. La Estancia', 'Aguascalientes', '5E', '505', 5),
('20060', 'Avenida Universidad', 'Col. Bosques', 'Aguascalientes', '6F', '606', 6),
('20070', 'Calle Jacarandas', 'Col. Primavera', 'Aguascalientes', '7G', '707', 7),
('20080', 'Calle Pinos', 'Col. San José', 'Aguascalientes', '8H', '808', 8),
('20090', 'Avenida Convención', 'Col. Del Valle', 'Aguascalientes', '9I', '909', 9),
('20100', 'Calle Cedros', 'Col. Morelos', 'Aguascalientes', '10J', '1010', 10),
('20110', 'Boulevard Miguel Ángel', 'Col. Santa Anita', 'Aguascalientes', '11K', '1111', 11),
('20120', 'Calle Laureles', 'Col. San Pablo', 'Aguascalientes', '12L', '1212', 12),
('20130', 'Avenida Independencia', 'Col. Altavista', 'Aguascalientes', '13M', '1313', 13),
('20140', 'Calle Abetos', 'Col. San Rafael', 'Aguascalientes', '14N', '1414', 14),
('20150', 'Boulevard San Marcos', 'Col. Jardines', 'Aguascalientes', '15O', '1515', 15),
('20160', 'Calle Cipreses', 'Col. La Soledad', 'Aguascalientes', '16P', '1616', 16),
('20170', 'Avenida Constitución', 'Col. Los Ángeles', 'Aguascalientes', '17Q', '1717', 17);

select * from direccion

ALTER TABLE Estudio
ADD COLUMN fecha_hora TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;

select * from estudio

INSERT INTO Estudio (nombre, descripcion, resultados, id_paciente) VALUES
('Radiografía Panorámica', 'Panorámica general', 'Sin anomalías graves', 1),
('Radiografía 3D', 'Estudio para extracción', 'Molar impactado', 2),
('Fotografía dental', 'Evaluación estética', 'Caries superficial', 3),
('Radiografía Periapical', 'Dolor específico', 'Posible infección', 4),
('Estudio blanqueamiento', 'Evaluación inicial', 'Apto para tratamiento', 5);

INSERT INTO Cita (fecha_hora, hora, descripcion, estado_cita, id_paciente) VALUES
('2025-12-01', '09:00:00', 'Consulta general', 'Atendida', 1),
('2025-12-11', '10:30:00', 'Limpieza dental', 'Pendiente', 2),
('2025-12-12', '11:15:00', 'Extracción molar', 'Confirmada', 3),
('2025-12-13', '14:00:00', 'Aplicación de resina', 'Reprogramada', 4),
('2025-12-14', '16:00:00', 'Blanqueamiento dental', 'Atendida', 5),
('2025-12-13', '09:45:00', 'Revisión general', 'Agendada', 6),
('2025-12-15', '13:30:00', 'Tratamiento dolor dental', 'Confirmada', 7),
('2025-12-17', '15:00:00', 'Ortodoncia inicial', 'Pendiente', 8),
('2025-12-18', '10:00:00', 'Control brackets', 'Reprogramada', 9),
('2025-12-19', '12:00:00', 'Extracción de muela del juicio', 'Cancelada', 10),
('2025-12-20', '09:30:00', 'Revisión preventiva', 'No asistio', 11),
('2025-12-21', '11:00:00', 'Aplicación de selladores', 'Pendiente', 12),
('2025-12-22', '14:15:00', 'Tratamiento de caries', 'Confirmada', 13),
('2025-12-23', '16:45:00', 'Blanqueamiento estético', 'Agendada', 14),
('2025-12-24', '08:30:00', 'Revisión ortodoncia', 'Atendida', 15),
('2025-12-25', '13:00:00', 'Limpieza profunda', 'Pendiente', 16),
('2025-12-26', '17:00:00', 'Revisión general', 'Agendada', 17);

INSERT INTO Cita (id_cita, fecha_hora, hora, descripcion, estado_cita, id_paciente) VALUES
-- FECHA: 15 de Enero 2026 (Jueves - Un día con mucha carga)
(100, '2026-01-15', '09:00:00', 'Limpieza semestral y revisión', 'Agendada', 1),
(101, '2026-01-15', '10:00:00', 'Ajuste de brackets mensual', 'Agendada', 8),
(102, '2026-01-15', '11:30:00', 'Valoración por dolor en muela', 'Pendiente', 12),
(103, '2026-01-15', '13:00:00', 'Entrega de guarda oclusal', 'Agendada', 3),
(104, '2026-01-15', '16:00:00', 'Blanqueamiento sesión 2', 'Confirmada', 5),
(105, '2026-01-15', '17:30:00', 'Extracción premolar', 'Reprogramada', 7),

-- FECHA: 16 de Enero 2026 (Viernes)
(106, '2026-01-16', '09:00:00', 'Consulta general revisión', 'Agendada', 2),
(107, '2026-01-16', '11:00:00', 'Resina estética sector anterior', 'Agendada', 4),
(108, '2026-01-16', '12:30:00', 'Curación post-extracción', 'Pendiente', 10),
(109, '2026-01-16', '16:00:00', 'Limpieza profunda', 'Agendada', 16),
(110, '2026-01-16', '18:00:00', 'Valoración de ortodoncia', 'Agendada', 14),

-- FECHA: 20 de Enero 2026 (Lunes)
(111, '2026-01-20', '10:00:00', 'Ajuste de ligas ortodoncia', 'Agendada', 15),
(112, '2026-01-20', '11:00:00', 'Revisión general anual', 'Confirmada', 17),
(113, '2026-01-20', '12:00:00', 'Valoración para implante', 'Pendiente', 6),
(114, '2026-01-20', '16:00:00', 'Resina molar 36', 'Agendada', 9),
(115, '2026-01-20', '17:00:00', 'Profilaxis infantil', 'Agendada', 11),

-- FECHA: 22 de Enero 2026 (Miércoles - Casos de reprogramación)
(116, '2026-01-22', '09:30:00', 'Cementación de corona', 'Reprogramada', 1),
(117, '2026-01-22', '11:00:00', 'Endodoncia sesión 1', 'Agendada', 13),
(118, '2026-01-22', '13:00:00', 'Revisión de caries', 'Pendiente', 5),
(119, '2026-01-22', '16:30:00', 'Limpieza dental simple', 'Agendada', 2),

-- FECHA: 30 de Enero 2026 (Viernes - Fin de mes)
(120, '2026-01-30', '10:00:00', 'Retiro de puntos', 'Agendada', 7),
(121, '2026-01-30', '11:30:00', 'Valoración estética', 'Confirmada', 8),
(122, '2026-01-30', '15:00:00', 'Blanqueamiento dental final', 'Agendada', 3),

-- FECHA: 05 de Febrero 2026 (Futuro lejano)
(123, '2026-02-05', '09:00:00', 'Control mensual ortodoncia', 'Agendada', 15),
(124, '2026-02-05', '10:00:00', 'Control mensual ortodoncia', 'Agendada', 9),
(125, '2026-02-05', '11:00:00', 'Control mensual ortodoncia', 'Agendada', 8),

-- FECHA: 14 de Febrero 2026 (Día especial)
(126, '2026-02-14', '10:00:00', 'Limpieza en pareja (1)', 'Pendiente', 4),
(127, '2026-02-14', '11:00:00', 'Limpieza en pareja (2)', 'Pendiente', 12),
(128, '2026-02-14', '16:00:00', 'Diseño de sonrisa', 'Agendada', 6),
(129, '2026-02-14', '18:00:00', 'Urgencia dolor', 'Agendada', 17);

--Los pacientes con citas 'Pendiente', 'Agendada' o 'Confirmada' (como el 2, 3, 4, etc.) NO deben tener historial clínico todavía, porque el evento médico aún no ocurre.
-- Historial para Cita 1 (Paciente 1 - Atendida - 2025-12-01)
SELECT * FROM HISTORIAL_CLINICO
select * from cita

INSERT INTO Historial_Clinico (alergias, enfermedades, avanceTratamiento, fecha, id_cita) VALUES
('Ninguna', 'Gingivitis leve', 'Limpieza y revisión general completada sin dolor.', '2025-12-01', 61);
-- Historial para Cita 5 (Paciente 5 - Atendida - 2025-12-14)
INSERT INTO Historial_Clinico (alergias, enfermedades, avanceTratamiento, fecha, id_cita) VALUES
('Ninguna', 'Dientes pigmentados', 'Primera sesión de blanqueamiento realizada con éxito.', '2025-12-14', 57);
-- Historial para Cita 15 (Paciente 15 - Atendida - 2025-12-24)
INSERT INTO Historial_Clinico (alergias, enfermedades, avanceTratamiento, fecha, id_cita) VALUES
('Polvo', 'Ninguna', 'Ajuste de brackets y cambio de ligas. Higiene aceptable.', '2025-12-24', 67);


select * from pago
select * from cita
-- Pago Cita 1 (Consulta/Limpieza - Completo)
INSERT INTO Pago (cantidadPagada, id_cita, metodoPagoid_metodopago) VALUES
(500, 53, 1); -- Efectivo

-- Pago Cita 3 (Extracción - Abono parcial para apartar)
INSERT INTO Pago (cantidadPagada, id_cita, metodoPagoid_metodopago) VALUES
(200, 55, 2); -- Transferencia

-- Pago Cita 5 (Blanqueamiento - Completo)
INSERT INTO Pago (cantidadPagada, id_cita, metodoPagoid_metodopago) VALUES
(1200, 57, 2); -- Transferencia

-- Pago Cita 15 (Ortodoncia revisión - Completo)
INSERT INTO Pago (cantidadPagada, id_cita, metodoPagoid_metodopago) VALUES
(500, 67, 1); -- Efectivo
select * from cita


-- Deuda Cita 1: Pagada totalmente
INSERT INTO Deuda (monto_pagado, monto_total, saldo_pendiente, id_cita, estado) VALUES
(500, 500, 0, 53, 'Pagada');
select * from cita

-- Deuda Cita 3: Costaba 800, abonó 200, debe 600
INSERT INTO Deuda (monto_pagado, monto_total, saldo_pendiente, id_cita, estado) VALUES
(200, 800, 600, 55, 'Abono');

-- Deuda Cita 5: Pagada totalmente
INSERT INTO Deuda (monto_pagado, monto_total, saldo_pendiente, id_cita, estado) VALUES
(1200, 1200, 0, 57, 'Pagada');

select * from cita
-- Deuda Cita 15: Pagada totalmente
INSERT INTO Deuda (monto_pagado, monto_total, saldo_pendiente, id_cita, estado) VALUES
(500, 500, 0, 67, 'Pagada');

-- Detalle Cita 1: Limpieza Dental (Tratamiento 1) + Material General (Material 5)
INSERT INTO Detalle_Costo (cantidad, subTotal, id_cita, id_tipo_tratamiento, id_tipo_material, id_pago) VALUES
(1, 500, 53, 1, 5, 1);

-- Detalle Cita 3: Extracción (Tratamiento 3) + Anestesia (Material 1)
-- Nota: El subtotal aquí refleja lo pagado en ese momento o el costo total, 
-- dependiendo de tu regla de negocio. Pondremos el costo total del item.
select * from cita
INSERT INTO Detalle_Costo (cantidad, subTotal, id_cita, id_tipo_tratamiento, id_tipo_material, id_pago) VALUES
(1, 800, 55, 3, 1, 2); 

-- Detalle Cita 5: Blanqueamiento (Tratamiento 5) + Blanqueador (Material 4)
INSERT INTO Detalle_Costo (cantidad, subTotal, id_cita, id_tipo_tratamiento, id_tipo_material, id_pago) VALUES
(1, 1200, 57, 5, 4, 3);

-- Detalle Cita 15: Ortodoncia/Revisión (Tratamiento 2) + Material Ortodoncia (Material 3)
INSERT INTO Detalle_Costo (cantidad, subTotal, id_cita, id_tipo_tratamiento, id_tipo_material, id_pago) VALUES
(1, 500, 67, 2, 3, 4);


-- CITA 53 (Atendida - Paciente 1)
INSERT INTO Usuario_Empleados_Cita (id_cita, id_usuario, tipo_empleado) VALUES
(53, 2, 'Dentista'),  -- Juan
(53, 1, 'Recepcion'); -- Carlos

-- CITA 54 (Pendiente - Paciente 2)
INSERT INTO Usuario_Empleados_Cita (id_cita, id_usuario, tipo_empleado) VALUES
(54, 4, 'Dentista'),  -- Diana
(54, 1, 'Recepcion');

-- CITA 55 (Confirmada - Paciente 3)
INSERT INTO Usuario_Empleados_Cita (id_cita, id_usuario, tipo_empleado) VALUES
(55, 2, 'Dentista'),
(55, 1, 'Recepcion');

-- CITA 56 (Reprogramada - Paciente 4)
INSERT INTO Usuario_Empleados_Cita (id_cita, id_usuario, tipo_empleado) VALUES
(56, 4, 'Dentista'),
(56, 1, 'Recepcion');

-- CITA 57 (Atendida - Paciente 5)
INSERT INTO Usuario_Empleados_Cita (id_cita, id_usuario, tipo_empleado) VALUES
(57, 2, 'Dentista'),
(57, 1, 'Recepcion');

-- CITA 58 (Agendada - Paciente 6)
INSERT INTO Usuario_Empleados_Cita (id_cita, id_usuario, tipo_empleado) VALUES
(58, 4, 'Dentista'),
(58, 1, 'Recepcion');

-- CITA 59 (Confirmada - Paciente 7)
INSERT INTO Usuario_Empleados_Cita (id_cita, id_usuario, tipo_empleado) VALUES
(59, 2, 'Dentista'),
(59, 1, 'Recepcion');

-- CITA 60 (Pendiente - Paciente 8)
INSERT INTO Usuario_Empleados_Cita (id_cita, id_usuario, tipo_empleado) VALUES
(60, 4, 'Dentista'),
(60, 1, 'Recepcion');

-- CITA 61 (Reprogramada - Paciente 9)
INSERT INTO Usuario_Empleados_Cita (id_cita, id_usuario, tipo_empleado) VALUES
(61, 2, 'Dentista'),
(61, 1, 'Recepcion');

-- CITA 62 (Cancelada - Paciente 10)
INSERT INTO Usuario_Empleados_Cita (id_cita, id_usuario, tipo_empleado) VALUES
(62, 4, 'Dentista'),
(62, 1, 'Recepcion');

-- CITA 63 (No asistio - Paciente 11)
INSERT INTO Usuario_Empleados_Cita (id_cita, id_usuario, tipo_empleado) VALUES
(63, 2, 'Dentista'),
(63, 1, 'Recepcion');

-- CITA 64 (Pendiente - Paciente 12)
INSERT INTO Usuario_Empleados_Cita (id_cita, id_usuario, tipo_empleado) VALUES
(64, 4, 'Dentista'),
(64, 1, 'Recepcion');

-- CITA 65 (Confirmada - Paciente 13)
INSERT INTO Usuario_Empleados_Cita (id_cita, id_usuario, tipo_empleado) VALUES
(65, 2, 'Dentista'),
(65, 1, 'Recepcion');

-- CITA 66 (Agendada - Paciente 14)
INSERT INTO Usuario_Empleados_Cita (id_cita, id_usuario, tipo_empleado) VALUES
(66, 4, 'Dentista'),
(66, 1, 'Recepcion');

-- CITA 67 (Atendida - Paciente 15)
INSERT INTO Usuario_Empleados_Cita (id_cita, id_usuario, tipo_empleado) VALUES
(67, 2, 'Dentista'),
(67, 1, 'Recepcion');

-- CITA 68 (Pendiente - Paciente 16)
INSERT INTO Usuario_Empleados_Cita (id_cita, id_usuario, tipo_empleado) VALUES
(68, 4, 'Dentista'),
(68, 1, 'Recepcion');

-- CITA 69 (Agendada - Paciente 17)
INSERT INTO Usuario_Empleados_Cita (id_cita, id_usuario, tipo_empleado) VALUES
(69, 2, 'Dentista'),
(69, 1, 'Recepcion');

-- 1. Asignar Recepcionista (Carlos - ID 1) a TODAS las nuevas citas
INSERT INTO Usuario_Empleados_Cita (id_cita, id_usuario, tipo_empleado)
SELECT id_cita, 1, 'Recepcion'
FROM Cita WHERE id_cita BETWEEN 100 AND 129;

-- 2. Asignar Dentista Juan (ID 2) a las citas pares
INSERT INTO Usuario_Empleados_Cita (id_cita, id_usuario, tipo_empleado)
SELECT id_cita, 2, 'Dentista'
FROM Cita WHERE id_cita BETWEEN 100 AND 129 AND (id_cita % 2) = 0;

-- 3. Asignar Dentista Diana (ID 4) a las citas impares
INSERT INTO Usuario_Empleados_Cita (id_cita, id_usuario, tipo_empleado)
SELECT id_cita, 4, 'Dentista'
FROM Cita WHERE id_cita BETWEEN 100 AND 129 AND (id_cita % 2) != 0;
-- Derivación Paciente 3 (José - Extracción complicada) -> Cirujano Maxilofacial
INSERT INTO Derivacion (fecha, nombreDentista, motivo, especialidadDentista, apellidoPatDentista, apellidoMatDentista, id_paciente, fecha_hora) VALUES
('2025-12-10', 'Laura', 'Raíz fusionada al hueso', 'Cirujano Maxilofacial', 'Perez', 'Ruiz', 3, '2025-12-10 10:00:00');

-- Derivación Paciente 7 (Estéban - Dolor dental) -> Endodoncista
INSERT INTO Derivacion (fecha, nombreDentista, motivo, especialidadDentista, apellidoPatDentista, apellidoMatDentista, id_paciente, fecha_hora) VALUES
('2025-12-14', 'Patricia', 'Posible necesidad de endodoncia', 'Endodoncista', 'Gomez', 'Soto', 7, '2025-12-14 14:00:00');

-- Derivación Paciente 10 (Fernando - Muela del juicio) -> Cirujano
INSERT INTO Derivacion (fecha, nombreDentista, motivo, especialidadDentista, apellidoPatDentista, apellidoMatDentista, id_paciente, fecha_hora) VALUES
('2025-12-18', 'Ricardo', 'Muela del juicio impactada horizontalmente', 'Cirujano Dental', 'Mendoza', 'Lara', 10, '2025-12-18 11:30:00');

-- Derivación Paciente 15 (Renata - Ortodoncia) -> Ortodoncista (Estudio cefalométrico externo)
INSERT INTO Derivacion (fecha, nombreDentista, motivo, especialidadDentista, apellidoPatDentista, apellidoMatDentista, id_paciente, fecha_hora) VALUES
('2025-12-22', 'Roberto', 'Estudio cefalométrico especializado', 'Ortodoncista', 'Martinez', 'Garcia', 15, '2025-12-22 09:00:00');



--NUEVOS INSERTS PARA LAS CONSULTAS DEL NODEE
SELECT * FROM PACIENTE
 SELECT id_paciente, nombrespaciente, apellidopat, apellidomat, telefono,email
      FROM paciente
      ORDER BY nombrespaciente;


-------FUNCIONES TRIGGER-------
--1 Actualizar saldo pendiente en Deuda--
CREATE OR REPLACE FUNCTION fn_actualizar_saldo_deuda()
RETURNS TRIGGER AS $$
BEGIN
    --Calcular el saldo pendiente
    NEW.saldo_pendiente = NEW.monto_total - NEW.monto_pagado;
    --Determinar el estado
    IF NEW.saldo_pendiente <= 0 THEN
        NEW.estado = 'Pagada';
    ELSIF NEW.monto_pagado > 0 THEN
        NEW.estado = 'Abono';
    ELSE
        NEW.estado = 'Pendiente a pagar';
    END IF;
    --Asegurar que el monto pagado no exceda el total
    IF NEW.monto_pagado > NEW.monto_total THEN
        RAISE EXCEPTION 'El monto pagado (%) no puede ser mayor que el monto total (%)', NEW.monto_pagado, NEW.monto_total;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
--TRIGGER
CREATE TRIGGER tr_actualizar_deuda
BEFORE INSERT OR UPDATE ON Deuda
FOR EACH ROW
EXECUTE FUNCTION fn_actualizar_saldo_deuda();
--PRUEBA
--Insertamos una deuda para una cita 
INSERT INTO Deuda (monto_total, monto_pagado, id_cita) 
VALUES (500, 500, 53);

-- COMPROBACIÓN:
-- Debería decir: saldo_pendiente = 0, estado = 'Pagada'
SELECT * FROM Deuda WHERE id_cita = 53;


--2 Verificar stock antes de usar material--
CREATE OR REPLACE FUNCTION fn_verificar_stock()
RETURNS TRIGGER AS $$
DECLARE
    v_stock_actual INTEGER;
    v_cantidad_por_uso INTEGER;
    v_material_requerido INTEGER;
BEGIN
    -- 1. Obtener el stock actual y la cantidad necesaria
    SELECT stock, cantidad INTO v_stock_actual, v_cantidad_por_uso
    FROM Material_Tratamiento
    WHERE id_tipo_material = NEW.id_tipo_material;

    -- 2. Verificar si el material existe (si no existe, las variables serán NULL)
    IF v_cantidad_por_uso IS NULL OR v_stock_actual IS NULL THEN
        RAISE EXCEPTION 'Error de configuración: El tipo de material ID % no tiene stock definido o no existe.', NEW.id_tipo_material;
    END IF;

    -- 3. Calcular material requerido
    v_material_requerido := NEW.cantidad * v_cantidad_por_uso;

    -- 4. Verificar si hay suficiente stock
    IF v_stock_actual < v_material_requerido THEN
        -- Aquí estaba el error probable. He limpiado la sintaxis:
        RAISE EXCEPTION 'Stock insuficiente para Material ID %. Requerido: %. Cantidad por uso: %. Disponible: %.', 
            NEW.id_tipo_material, 
            v_material_requerido, 
            v_cantidad_por_uso, 
            v_stock_actual;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- RECREAR EL TRIGGER (Por si acaso)
CREATE TRIGGER tr_verificar_stock_detalle
BEFORE INSERT ON Detalle_Costo
FOR EACH ROW
EXECUTE FUNCTION fn_verificar_stock();
--PRUEBA
--Verificar el stock inicial
SELECT stock, cantidad AS cantidad_por_uso
FROM Material_Tratamiento
WHERE id_tipo_material = 2;
--Simular un insert (que consume stock)
INSERT INTO Detalle_Costo (cantidad, subTotal, id_cita, id_tipo_tratamiento, id_tipo_material, id_pago) 
VALUES (51, 28800, 53, 4, 2, 3);
--Verificar stock final
SELECT stock FROM Material_Tratamiento WHERE id_tipo_material = 2;


--3 Actualizar stock de material después de usar--
CREATE OR REPLACE FUNCTION fn_reducir_stock_material()
RETURNS TRIGGER AS $$
DECLARE
    v_cantidad_por_uso INTEGER;
BEGIN
    --Obtener la cantidad de material que se consume (por unidad de tratamiento)
    SELECT cantidad INTO v_cantidad_por_uso
    FROM Material_Tratamiento
    WHERE id_tipo_material = NEW.id_tipo_material;
    --Reducir el stock
    UPDATE Material_Tratamiento
    SET stock = stock - (NEW.cantidad * v_cantidad_por_uso)
    WHERE id_tipo_material = NEW.id_tipo_material;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
--TRIGGER
CREATE TRIGGER tr_reducir_stock
AFTER INSERT ON Detalle_Costo
FOR EACH ROW
EXECUTE FUNCTION fn_reducir_stock_material();
--PRUEBA
--Verificar stock inicial
SELECT stock FROM Material_Tratamiento WHERE id_tipo_material = 2;
--Simular INSERT que consume stock
INSERT INTO Detalle_Costo (cantidad, subTotal, id_cita, id_tipo_tratamiento, id_tipo_material, id_pago) 
VALUES (5, 4000, 53, 4, 2, 3);

--4 Controlar el estado de cita para historial clínico--
CREATE OR REPLACE FUNCTION fn_verificar_cita_atendida()
RETURNS TRIGGER AS $$
DECLARE
    v_estado_cita VARCHAR(100);
BEGIN
    SELECT estado_cita INTO v_estado_cita
    FROM Cita
    WHERE id_cita = NEW.id_cita;
    IF v_estado_cita <> 'Atendida' THEN
        RAISE EXCEPTION 'No se puede crear Historial Clínico. La Cita ID % no ha sido marcada como "Atendida". Estado actual: %', 
            NEW.id_cita, v_estado_cita;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
--TRIGGER
CREATE TRIGGER tr_historial_solo_atendida
BEFORE INSERT ON Historial_Clinico
FOR EACH ROW
EXECUTE FUNCTION fn_verificar_cita_atendida();
--PRUEBA
--Verificar estado de la cita
select * from cita
UPDATE Cita SET estado_cita = 'Agendada' WHERE id_cita = 60;
--Intentar crear un historial para la cita 1, que está "agendada".
INSERT INTO Historial_Clinico (alergias, enfermedades, avanceTratamiento, fecha, id_cita) 
VALUES ('Polen', 'Ninguna', 'Inicio', CURRENT_DATE, 66);
--INSERT exitoso
UPDATE Cita SET estado_cita = 'Atendida' WHERE id_cita = 66; 
INSERT INTO Historial_Clinico (alergias, enfermedades, avanceTratamiento, fecha, id_cita) 
VALUES ('Polen', 'Ninguna', 'Inicio', CURRENT_DATE, 66);

select * from historial_clinico
select * from cita

-------FUNCIONES CON CURSORES-------
--1 Obtener historial completo de un paciente--
CREATE OR REPLACE FUNCTION fn_obtener_historial_completo_paciente(p_id_paciente INTEGER)
RETURNS TABLE (
    cita_id INTEGER,
    fecha_cita DATE,
    descripcion_cita VARCHAR,
    alergias_historial VARCHAR,
    enfermedades_historial VARCHAR
) AS $$
DECLARE
--CURSOR (itera sobre las citas de un paciente)
    cur_citas CURSOR FOR
        SELECT
            c.id_cita,
            c.fecha_hora,
            c.descripcion,
            hc.alergias,
            hc.enfermedades
        FROM Cita c
        LEFT JOIN Historial_Clinico hc ON c.id_cita = hc.id_cita
        WHERE c.id_paciente = p_id_paciente
        ORDER BY c.fecha_hora DESC;
    reg_cita RECORD;
BEGIN
    OPEN cur_citas;
    LOOP
        FETCH cur_citas INTO reg_cita;
        EXIT WHEN NOT FOUND;
        --Devolver la fila actual
        cita_id := reg_cita.id_cita;
        fecha_cita := reg_cita.fecha_hora;
        descripcion_cita := reg_cita.descripcion;
        alergias_historial := reg_cita.alergias;
        enfermedades_historial := reg_cita.enfermedades;
        RETURN NEXT;
    END LOOP;
    CLOSE cur_citas;
    RETURN;
END;
$$ LANGUAGE plpgsql;
--PRUEBA
select * from historial_clinico
SELECT * FROM fn_obtener_historial_completo_paciente(3);


--2 Actualizar citas a "No asistió" para fechas pasadas pendientes--
CREATE OR REPLACE FUNCTION fn_actualizar_citas_no_asistidas()
RETURNS INTEGER AS $$
DECLARE
    v_citas_actualizadas INTEGER := 0;
--CURSOR para encontrar citas pasadas y no atendidas
    cur_citas CURSOR FOR
        SELECT id_cita
        FROM Cita
        WHERE fecha_hora < CURRENT_DATE
          AND estado_cita IN ('Agendada', 'Pendiente');
    v_id_cita INTEGER;
BEGIN
    OPEN cur_citas;
    LOOP
        FETCH cur_citas INTO v_id_cita;
        EXIT WHEN NOT FOUND;
        --Actualizar el estado de la cita
        UPDATE Cita
        SET estado_cita = 'No asistio'
        WHERE id_cita = v_id_cita;
        v_citas_actualizadas := v_citas_actualizadas + 1;
    END LOOP;
    CLOSE cur_citas;
    RETURN v_citas_actualizadas; --Retorna el número de citas actualizadas
END;
$$ LANGUAGE plpgsql;
--PRUEBA
SELECT fn_actualizar_citas_no_asistidas(); --AÚN NO HAY


--3 Calcular monto total de pagos por método en un rango de fechas--
CREATE OR REPLACE FUNCTION fn_reporte_pagos_por_metodo(p_fecha_inicio DATE, p_fecha_fin DATE)
RETURNS TABLE (
    nombre_metodo VARCHAR,
    monto_total_pagado BIGINT
) AS $$
DECLARE
--CURSOR para agrupar y sumar pagos
    cur_pagos CURSOR FOR
        SELECT
            mp.nombre_metodo,
            SUM(p.cantidadPagada) AS total_pagado
        FROM Pago p
        JOIN Metodo_Pago mp ON p.metodoPagoid_metodopago = mp.id_metodo_pago
        -- 🎯 CORRECCIÓN: Usar 'fecha_hora' y convertirla a DATE para comparar
        WHERE p.fecha_hora::DATE BETWEEN p_fecha_inicio AND p_fecha_fin
        GROUP BY mp.nombre_metodo;
    reg_pago RECORD;
BEGIN
    OPEN cur_pagos;
    LOOP
        FETCH cur_pagos INTO reg_pago;
        EXIT WHEN NOT FOUND;
        nombre_metodo := reg_pago.nombre_metodo;
        monto_total_pagado := reg_pago.total_pagado;
        RETURN NEXT;
    END LOOP;
    CLOSE cur_pagos;
    RETURN;
END;
$$ LANGUAGE plpgsql;
--PRUEBA
SELECT * FROM fn_reporte_pagos_por_metodo('2025-12-01', '2025-12-28');


--4 Actualizar el costo de tratamiento en Detalle_Costo--
CREATE OR REPLACE FUNCTION fn_recalcular_detalle_costo_cita(p_id_cita INTEGER)
RETURNS INTEGER AS $$
DECLARE
    v_detalles_actualizados INTEGER := 0;
--CURSOR para recorrer los detalles de costo de la cita
    cur_detalles CURSOR FOR
        SELECT id_detalle, id_tipo_tratamiento, cantidad
        FROM Detalle_Costo
        WHERE id_cita = p_id_cita
        FOR UPDATE; --Bloquear la fila para la actualización
    reg_detalle RECORD;
    v_nuevo_subtotal INTEGER;
BEGIN
    OPEN cur_detalles;
    LOOP
        FETCH cur_detalles INTO reg_detalle;
        EXIT WHEN NOT FOUND;
        --Calcular el nuevo subTotal
        SELECT reg_detalle.cantidad * costo INTO v_nuevo_subtotal
        FROM Tratamiento
        WHERE id_tipo_tratamiento = reg_detalle.id_tipo_tratamiento;
        --Actualizar el subTotal
        UPDATE Detalle_Costo
        SET subTotal = v_nuevo_subtotal
        WHERE CURRENT OF cur_detalles;
        v_detalles_actualizados := v_detalles_actualizados + 1;
    END LOOP;
    CLOSE cur_detalles;
    
    RETURN v_detalles_actualizados;
END;
$$ LANGUAGE plpgsql;
--PRUEBA
SELECT fn_recalcular_detalle_costo_cita(53);


--5 Listar pacientes con deuda pendiente--
CREATE OR REPLACE FUNCTION fn_listar_pacientes_con_deuda()
RETURNS TABLE (
    id_paciente INTEGER,
    nombre_completo VARCHAR,
    saldo_pendiente_total BIGINT
) AS $$
DECLARE
--CURSOR para seleccionar pacientes con deuda pendiente
    cur_deudas CURSOR FOR
        SELECT 
            p.id_paciente,
            p.nombresPaciente || ' ' || p.apellidoPat AS nombre_completo,
            SUM(d.saldo_pendiente) AS saldo_total
        FROM Paciente p
        JOIN Cita c ON p.id_paciente = c.id_paciente
        JOIN Deuda d ON c.id_cita = d.id_cita
        WHERE d.saldo_pendiente > 0
        GROUP BY p.id_paciente, nombre_completo
        HAVING SUM(d.saldo_pendiente) > 0;
    reg_deuda RECORD;
BEGIN
    OPEN cur_deudas;
    LOOP
        FETCH cur_deudas INTO reg_deuda;
        EXIT WHEN NOT FOUND;
        id_paciente := reg_deuda.id_paciente;
        nombre_completo := reg_deuda.nombre_completo;
        saldo_pendiente_total := reg_deuda.saldo_total;
        RETURN NEXT;
    END LOOP;
    CLOSE cur_deudas;
    RETURN;
END;
$$ LANGUAGE plpgsql;
--PRUEBA
SELECT * FROM fn_listar_pacientes_con_deuda();

--VISTAS
select * from CITA;
select * from paciente;
select * from derivacion
select * from deuda;
select * from direccion;
select * from estudio
select * from historial_clinico;
select * from material_tratamiento;
select * from metodo_pago;
select * from paciente;
select * from pago
select * from tipo_material;
select * from tratamiento;
select * from usuario_empleado;
select * from usuario_empleados_cita;

select * from vista_citas_empleados; -- no
select * from vista_citas_paciente; -- no 
SELECT * FROM vista_derivaciones_externas; --SI -LISTO
select * from vista_historial_paciente; -- SI - LISTO
select * from vista_reporte_cita_completa; --si -LISTO 
select * from vista_tratamientos_realizados; --SI - LISTO

CREATE OR REPLACE VIEW vista_tratamientos_realizados AS
SELECT
    c.id_paciente,
    t.nombre AS nombre_tratamiento,
    t.costo,
    dc.cantidad AS unidades_tratamiento,
    dc.subTotal,
    c.fecha_hora AS fecha_tratamiento 
FROM
    Detalle_Costo dc
JOIN
    Tratamiento t ON dc.id_tipo_tratamiento = t.id_tipo_tratamiento
JOIN
    Cita c ON dc.id_cita = c.id_cita
ORDER BY
    c.fecha_hora DESC;

CREATE OR REPLACE VIEW vista_derivaciones_externas AS
SELECT
    d.id_paciente,
    -- Concatenamos el nombre para mostrarlo en la tabla
    p.nombrespaciente || ' ' || p.apellidoPat AS nombre_paciente,
    d.fecha, 
    d.motivo,
    d.especialidadDentista, -- Asegúrate que en tu tabla sea así, o 'especialidaddentista' (minúsculas)
    d.nombreDentista || ' ' || d.apellidoPatDentista AS especialista_destino
FROM
    Derivacion d
JOIN
    Paciente p ON d.id_paciente = p.id_paciente
ORDER BY
    d.fecha DESC;

CREATE OR REPLACE VIEW vista_reporte_cita_completa AS --SII
SELECT
    c.id_cita,
    c.fecha_hora,
    p.id_paciente,
    --  el nombre completo del paciente
    p.nombrespaciente || ' ' || p.apellidoPat || ' ' || p.apellidoMat AS paciente_nombre_completo,
    c.estado_cita,
    c.descripcion AS motivo_principal_cita,

    -- 1. EMPLEADOS INVOLUCRADOS (Dentista)
    STRING_AGG(
        DISTINCT CASE WHEN uec.tipo_empleado = 'Dentista' THEN ue.nombres || ' ' || ue.apellidoPat ELSE NULL END, 
        ', '
    ) AS dentistas_involucrados,
    
    -- 2. TRATAMIENTOS Y MATERIALES
    STRING_AGG(
        DISTINCT t.nombre || ' (' || dc.cantidad || ' unid.)', 
        ' | '
    ) AS tratamientos_y_cantidad,
    
    -- 3. RESUMEN DEL HISTORIAL (Mantener solo el avance y las enfermedades)
    MAX(hc.avanceTratamiento) AS historial_avance,
    MAX(hc.enfermedades) AS enfermedades_previas,
    
    -- 4. DERIVACIONES
    STRING_AGG(
        DISTINCT d.nombreDentista || ' (' || d.especialidadDentista || ') por ' || d.motivo, 
        ' | '
    ) AS derivaciones_registradas,
    
    -- 5. ESTUDIOS SOLICITADOS
    STRING_AGG(
        DISTINCT e.nombre || ' (' || e.resultados || ')', 
        ' | '
    ) AS estudios_realizados_o_solicitados

FROM
    Cita c
JOIN
    Paciente p ON c.id_paciente = p.id_paciente
LEFT JOIN
    Usuario_Empleados_Cita uec ON c.id_cita = uec.id_cita
LEFT JOIN
    Usuario_Empleado ue ON uec.id_usuario = ue.id_usuario
LEFT JOIN
    Historial_Clinico hc ON c.id_cita = hc.id_cita
LEFT JOIN
    Detalle_Costo dc ON c.id_cita = dc.id_cita
LEFT JOIN
    Tratamiento t ON dc.id_tipo_tratamiento = t.id_tipo_tratamiento
LEFT JOIN
    Derivacion d ON c.id_paciente = d.id_paciente 
LEFT JOIN
    Estudio e ON c.id_paciente = e.id_paciente 
GROUP BY
    c.id_cita, c.fecha_hora, p.id_paciente, p.nombrespaciente, p.apellidoPat, p.apellidoMat, c.estado_cita, c.descripcion
ORDER BY
    c.fecha_hora DESC;

--INDICE para la vista de "vista_reporte_cita_completa" es para consultas detallas y requiere muchos indices
CREATE INDEX idx_cita_id_paciente ON Cita (id_paciente);
CREATE INDEX idx_detallecosto_id_cita ON Detalle_Costo (id_cita);

--vista_historial_paciente
CREATE OR REPLACE VIEW vista_historial_paciente AS
SELECT
    c.id_paciente,
    hc.fecha AS fecha_historial,
    hc.alergias,
    hc.enfermedades,
    hc.avanceTratamiento,
    c.fecha_hora AS fecha_cita,
    c.descripcion AS motivo_cita
FROM
    Historial_Clinico hc
JOIN
    Cita c ON hc.id_cita = c.id_cita
ORDER BY
    hc.fecha DESC;
select * from vista_historial_paciente
select * from vista_derivaciones_externas
select * from vista_tratamientos_realizados
select * from vista_reporte_cita_completa

select * from material_tratamiento

-- Agrega la restricción UNIQUE a la columna id_cita en Historial_Clinico
ALTER TABLE Historial_Clinico
ADD CONSTRAINT uq_historial_id_cita UNIQUE (id_cita);

--NUEVOS INSERTS :
-- LOTE DE PRUEBAS: CITAS FUTURAS (ENERO - FEBRERO 2026)
-- IDs manuales del 100 al 129 para evitar choques con datos previos.
select * from cita
select * from usuario_empleado
--NUEVOS TRIGGERS Y FUNCIONES

/*
TRIGGERS DE NADIA :
Deudas
Stock
Citas
Historial 
Pacientes
Reportes
Pagos
*/

-----------------------------------------------------------------------AQUI
--trigger que actualiza la fecha de registro , fecha_hora cuando se edita el registro
select * from u

CREATE OR REPLACE FUNCTION fn_actualizar_fecha_modificacion()
RETURNS TRIGGER AS $$
BEGIN
    NEW.fecha_hora = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_actualizar_fecha_modificacion
BEFORE UPDATE ON Usuario_Empleado
FOR EACH ROW
EXECUTE FUNCTION fn_actualizar_fecha_modificacion();

--cursos : listar empleados por tipo
CREATE OR REPLACE FUNCTION fn_listar_empleados_por_tipo(p_tipo VARCHAR)
RETURNS TABLE(
    id_empleado INT,
    nombre_completo VARCHAR,
    tipo VARCHAR
) AS $$
DECLARE
    cur_empleados CURSOR FOR
        -- Agregamos el alias 'nom_completo' para poder llamarlo después
        SELECT id_usuario, (nombres || ' ' || apellidoPat || ' ' || apellidoMat) AS nom_completo, tipoEmpleado
        FROM Usuario_Empleado
        WHERE tipoEmpleado = p_tipo;
    reg RECORD;
BEGIN
    OPEN cur_empleados;
    LOOP
        FETCH cur_empleados INTO reg;
        EXIT WHEN NOT FOUND;

        id_empleado := reg.id_usuario;
        nombre_completo := reg.nom_completo; -- Ahora usamos el alias seguro
        tipo := reg.tipoEmpleado;

        RETURN NEXT;
    END LOOP;
    CLOSE cur_empleados;
END;
$$ LANGUAGE plpgsql;

--verifica si el nombre de usuario ya existe
CREATE OR REPLACE FUNCTION fn_usuario_existe(p_nombre VARCHAR)
RETURNS BOOLEAN AS $$
DECLARE
    existe BOOLEAN;
BEGIN
    SELECT TRUE INTO existe
    FROM Usuario_Empleado
    WHERE nombreUsuario = p_nombre;

    RETURN COALESCE(existe, FALSE);
END;
$$ LANGUAGE plpgsql;

--vista para mostar empleados activos sin el superadmin
drop view vista_empleados_activos
CREATE OR REPLACE VIEW vista_empleados_activos AS
SELECT 
    id_usuario,
    nombres,          -- Agregamos esto
    apellidoPat,      -- Agregamos esto
    apellidoMat,      -- Agregamos esto
    (nombres || ' ' || apellidoPat || ' ' || apellidoMat) AS nombre_completo,
    tipoEmpleado,
    fecha_hora
FROM Usuario_Empleado
WHERE superAdmin = 'false';

select * from vista_empleados_activos

--INSERCIONES A MAYUSCULAS
CREATE OR REPLACE FUNCTION fn_convertir_mayusculas()
RETURNS TRIGGER AS $$
BEGIN
    -- Verificar si el trigger se disparó en la tabla PACIENTE
    IF TG_TABLE_NAME = 'paciente' THEN
        -- Usamos UPPER para convertir a mayúsculas, y COALESCE para evitar error si viene NULL
        NEW.nombrespaciente := UPPER(NEW.nombrespaciente);
        NEW.apellidopat := UPPER(NEW.apellidopat);
        NEW.apellidomat := UPPER(NEW.apellidomat);
    
    -- Verificar si el trigger se disparó en la tabla USUARIO_EMPLEADO
    ELSIF TG_TABLE_NAME = 'usuario_empleado' THEN
        NEW.nombres := UPPER(NEW.nombres);
        NEW.apellidopat := UPPER(NEW.apellidopat);
        NEW.apellidomat := UPPER(NEW.apellidomat);
        -- Opcional: Si también quieres el nombre de usuario en mayúsculas
        -- NEW.nombreUsuario := UPPER(NEW.nombreUsuario); 
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para la tabla Paciente
DROP TRIGGER IF EXISTS tr_mayusculas_paciente ON Paciente;
CREATE TRIGGER tr_mayusculas_paciente
BEFORE INSERT OR UPDATE ON Paciente
FOR EACH ROW
EXECUTE FUNCTION fn_convertir_mayusculas();

-- Trigger para la tabla Usuario_Empleado
DROP TRIGGER IF EXISTS tr_mayusculas_usuario ON Usuario_Empleado;
CREATE TRIGGER tr_mayusculas_usuario
BEFORE INSERT OR UPDATE ON Usuario_Empleado
FOR EACH ROW
EXECUTE FUNCTION fn_convertir_mayusculas();

-- Actualizar Pacientes existentes
UPDATE Paciente
SET nombrespaciente = UPPER(nombrespaciente),
    apellidopat = UPPER(apellidopat),
    apellidomat = UPPER(apellidomat);

-- Actualizar Empleados existentes
UPDATE Usuario_Empleado
SET nombres = UPPER(nombres),
    apellidopat = UPPER(apellidopat),
    apellidomat = UPPER(apellidomat);


-----------------------------------------------------------------------------
SELECT 
                c.id_cita,
                c.fecha_hora,
                c.hora,
                c.descripcion AS motivo_principal_cita, -- Alias compatible con tu frontend
                c.estado_cita,
                c.id_paciente,
                -- Datos del Dentista
                ue.nombres || ' ' || ue.apellidoPat AS dentistas_involucrados,
                -- Datos del Paciente (Necesario para la tabla visual)
                p.nombrespaciente || ' ' || p.apellidoPat ||' '||p.apellidoMat AS paciente_nombre_completo
            FROM 
                Cita c
            -- 1. Unir Cita con la tabla intermedia
            JOIN 
                Usuario_Empleados_Cita uec ON c.id_cita = uec.id_cita
            -- 2. Unir la intermedia con la tabla de Empleados
            JOIN 
                Usuario_Empleado ue ON uec.id_usuario = ue.id_usuario
            -- 3. Unir con Paciente (Para saber de quién es la cita)
            JOIN
                Paciente p ON c.id_paciente = p.id_paciente
            
            -- 4. FILTROS BASE
            WHERE 
                uec.tipo_empleado = 'Dentista' and c.estado_cita='Agendada'

--ALTAS Y BAJAS
select * from material_tratamiento
select * from tipo_material; 
select * from tratamiento;
select * from tipo_tratamiento;
select * from cita;
SELECT * FROM PACIENTE;

select * from usuario_empleado
SELECT * FROM Usuario_Empleado where superadmin='true'
select * from paciente;
-------------FUNCIONES :
--TRATAMIENTOS : CONTAR TRATAMIENTOS POR PACIENTE
CREATE OR REPLACE FUNCTION fn_conteo_tratamientos_paciente(p_id_paciente INTEGER)
RETURNS BIGINT AS $$
DECLARE
    v_conteo BIGINT;
BEGIN
    SELECT COUNT(dc.id_tipo_tratamiento) INTO v_conteo
    FROM Detalle_Costo dc
    JOIN Cita c ON dc.id_cita = c.id_cita
    WHERE c.id_paciente = p_id_paciente;
    
    RETURN v_conteo;
END;
$$ LANGUAGE plpgsql;

-- PRUEBA
SELECT fn_conteo_tratamientos_paciente(1); -- Ejemplo: Paciente con ID 1

--COSTO PTOMEDIO DE TODOS LOS TRATAMIENTOS REGISTRADOS
CREATE OR REPLACE FUNCTION fn_costo_promedio_tratamientos()
RETURNS NUMERIC AS $$
DECLARE
    v_costo_promedio NUMERIC;
BEGIN
    SELECT AVG(costo) INTO v_costo_promedio
    FROM Tratamiento;
    
    -- Redondea a 2 decimales
    RETURN ROUND(v_costo_promedio, 2);
END;
$$ LANGUAGE plpgsql;

-- PRUEBA
SELECT fn_costo_promedio_tratamientos();

--ROLL UP GENERA REPORTES CON SUBTOTALES Y TOTOAL GENERAL
--REPORTE DE INGRESIS POR TRATAMIENTO
SELECT
    COALESCE(mp.nombre_metodo, 'TOTAL GENERAL') AS metodo_pago,
    COALESCE(t.nombre, 'SUBTOTAL PAGO') AS tratamiento,
    SUM(p.cantidadPagada) AS ingresos_totales
FROM
    Pago p
JOIN
    Metodo_Pago mp ON p.metodoPagoid_metodopago = mp.id_metodo_pago
JOIN
    Detalle_Costo dc ON p.idPago = dc.id_pago
JOIN
    Tratamiento t ON dc.id_tipo_tratamiento = t.id_tipo_tratamiento
GROUP BY
    ROLLUP(mp.nombre_metodo, t.nombre)
ORDER BY
    metodo_pago, tratamiento;

--AUMENTA :
CREATE OR REPLACE PROCEDURE sp_ajustar_precios_tratamiento(
    p_id_tratamiento INTEGER,
    p_porcentaje_ajuste NUMERIC
)
LANGUAGE plpgsql AS $$
BEGIN
    -- Se verifica que el porcentaje sea razonable (opcional)
    IF p_porcentaje_ajuste <= -100 OR p_porcentaje_ajuste > 500 THEN
        RAISE EXCEPTION 'Porcentaje de ajuste no válido.';
    END IF;

    -- Actualiza el costo aplicando el porcentaje
    UPDATE Tratamiento
    SET costo = costo + (costo * p_porcentaje_ajuste / 100)
    WHERE id_tipo_tratamiento = p_id_tratamiento;
    
    -- No es necesario un COMMIT explícito aquí si no se usa START TRANSACTION.
    -- El bloque PL/pgSQL es atómico por defecto si no hay errores.
END;
$$;

SELECT * FROM Tratamiento WHERE id_tipo_tratamiento = 1; -- Costo original: 500
CALL sp_ajustar_precios_tratamiento(1, 10); -- Aumenta 10% (a 550)
SELECT * FROM Tratamiento WHERE id_tipo_tratamiento = 1;
--BAJA LOGICA :
-- 1. Primero borramos posibles versiones viejas que causen ruido
DROP PROCEDURE IF EXISTS sp_gestionar_baja_tratamiento;
-- 2. Creamos el procedimiento INTELIGENTE con el nombre correcto
CREATE OR REPLACE PROCEDURE sp_gestionar_baja_tratamiento(p_id_tratamiento INTEGER)
LANGUAGE plpgsql AS $$
DECLARE
    v_veces_usado INTEGER;
BEGIN
    -- Verificamos si este tratamiento ya se usó en alguna cita (tabla Detalle_Costo)
    SELECT COUNT(*) INTO v_veces_usado
    FROM Detalle_Costo
    WHERE id_tipo_tratamiento = p_id_tratamiento;

    -- DECISIÓN:
    IF v_veces_usado = 0 THEN
        -- CASO A: Nadie lo ha usado (es seguro borrarlo físicamente)
        DELETE FROM Tratamiento WHERE id_tipo_tratamiento = p_id_tratamiento;
    ELSE
        -- CASO B: Ya tiene historial (Solo lo desactivamos/Baja Lógica)
        UPDATE Tratamiento SET activo = FALSE WHERE id_tipo_tratamiento = p_id_tratamiento;
    END IF;
END;
$$;


--PAGOS : ncontrar pacientes que tuvieron una Extracción (Tratamiento ID 3) Y tienen una Deuda Pendiente (saldo_pendiente > 0).
-- 1. Pacientes que han tenido una Extracción (Tratamiento ID 3)
SELECT c.id_paciente
FROM Cita c
JOIN Detalle_Costo dc ON c.id_cita = dc.id_cita
WHERE dc.id_tipo_tratamiento = 3

INTERSECT -- Solo aquellos ID que están en AMBOS conjuntos

-- 2. Pacientes que tienen una deuda pendiente (saldo_pendiente > 0)
SELECT c.id_paciente
FROM Cita c
JOIN Deuda d ON c.id_cita = d.id_cita
WHERE d.saldo_pendiente > 0

select * from tratamiento
SELECT * FROM Tratamiento WHERE activo = FALSE ORDER BY nombre

SELECT 
                p.nombrespaciente || ' ' || p.apellidopat AS nombre_paciente,
                t.nombre AS nombre_tratamiento,
                c.fecha_hora AS fecha_cita,
                dc.subTotal AS precio_original,
                d.estado AS estado_pago,
                d.saldo_pendiente
            FROM Detalle_Costo dc
            JOIN Tratamiento t ON dc.id_tipo_tratamiento = t.id_tipo_tratamiento
            JOIN Cita c ON dc.id_cita = c.id_cita
            JOIN Paciente p ON c.id_paciente = p.id_paciente
            JOIN Deuda d ON c.id_cita = d.id_cita  -- JOIN estricto, debe tener registro de deuda
            WHERE t.activo = FALSE
              AND d.saldo_pendiente > 0            -- <--- EL FILTRO CLAVE: Solo si deben dinero
            ORDER BY c.fecha_hora DESC;
----------------------------------------------------------------------------------------------------------------------------
--FUNCIONES Y VISTAS PARA EL INVENTARIO DE MATERIALES
/*
Vista de Valor del Inventario (Uso de SUM y AVG)
Esta vista le dirá al SuperAdmin cuánto dinero tiene invertido en insumos y cuál es el costo promedio por categoría.

SUM(mt.stock * mt.costoUnitario): Calcula el dinero total "parado" en el almacén.

AVG(mt.costoUnitario): Calcula el costo promedio de los materiales de esa categoría.*/

--Mostrar solo materiales cuyo stock sea menor a 10 unidades (o el número que le pases).
CREATE OR REPLACE FUNCTION fn_reporte_bajo_stock(p_limite_stock INTEGER)
RETURNS TABLE (
    nombre_material VARCHAR,
    categoria VARCHAR,
    stock_actual INTEGER,
    estado_alerta TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        mt.nombre,
        tm.nombre_tipo,
        mt.stock,
        CASE 
            WHEN mt.stock = 0 THEN 'AGOTADO'
            WHEN mt.stock <= 5 THEN 'CRÍTICO'
            ELSE 'BAJO'
        END AS estado_alerta
    FROM 
        Material_Tratamiento mt
    JOIN 
        Tipo_Material tm ON mt.id_tipo_material = tm.id_tipo_material
    GROUP BY 
        mt.id_material, mt.nombre, tm.nombre_tipo, mt.stock
    -- REQUISITO HAVING: Filtrar grupos después de la agregación o agrupación
    HAVING 
        mt.stock <= p_limite_stock
    ORDER BY 
        mt.stock ASC;
END;
$$ LANGUAGE plpgsql;

-- PRUEBA (Dame materiales con 10 o menos unidades)
SELECT * FROM fn_reporte_bajo_stock(100);

CREATE OR REPLACE VIEW vista_inventario_detallado_kpi AS
SELECT 
    -- 1. DATOS DE LA CATEGORÍA (Vienen de la tabla 'tm')
    tm.nombre_tipo AS categoria,
    tm.id_tipo_material,
    
    -- 2. KPIs AGREGADOS (Vienen de la subconsulta 'datos_agrupados')
    datos_agrupados.stock_total_categoria,
    datos_agrupados.valor_total_categoria,
    datos_agrupados.costo_promedio_categoria,

    -- 3. DATOS DEL MATERIAL (Vienen de la tabla 'mt')
    mt.id_material,
    mt.nombre AS material,
    mt.stock AS stock_individual,
    mt.costoUnitario AS costo_unitario,
    (mt.stock * mt.costoUnitario) AS valor_material_individual,
    
    -- 4. COMPARATIVA (Usamos el promedio calculado en la subconsulta)
    CASE 
        WHEN mt.costoUnitario > datos_agrupados.costo_promedio_categoria 
        THEN 'Sobre el Promedio'
        ELSE 'Bajo el Promedio'
    END AS comparativa_precio

FROM 
    Material_Tratamiento mt
JOIN 
    Tipo_Material tm ON mt.id_tipo_material = tm.id_tipo_material

-- AQUÍ ESTÁ LA MAGIA: UNIMOS CON UNA SUBCONSULTA QUE YA TIENE LOS TOTALES
JOIN (
    SELECT 
        id_tipo_material,
        -- Aquí aplicamos tus funciones requeridas con GROUP BY normal
        SUM(stock) AS stock_total_categoria,
        SUM(stock * costoUnitario) AS valor_total_categoria,
        ROUND(AVG(costoUnitario), 2) AS costo_promedio_categoria
    FROM 
        Material_Tratamiento
    GROUP BY 
        id_tipo_material
) datos_agrupados ON mt.id_tipo_material = datos_agrupados.id_tipo_material

ORDER BY 
    tm.nombre_tipo, mt.nombre;


--
CREATE OR REPLACE FUNCTION fn_categorias_alto_valor(p_monto_minimo NUMERIC)
RETURNS TABLE (
    categoria VARCHAR,
    total_materiales BIGINT,
    inversion_total BIGINT,
    costo_promedio NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        tm.nombre_tipo,
        COUNT(mt.id_material),
        SUM(mt.stock * mt.costoUnitario),
        ROUND(AVG(mt.costoUnitario), 2)
    FROM 
        Material_Tratamiento mt
    JOIN 
        Tipo_Material tm ON mt.id_tipo_material = tm.id_tipo_material
    GROUP BY 
        tm.nombre_tipo
    -- REQUISITO HAVING: Filtrar grupos basados en una suma agregada
    HAVING 
        SUM(mt.stock * mt.costoUnitario) >= p_monto_minimo
    ORDER BY 
        SUM(mt.stock * mt.costoUnitario) DESC;
END;
$$ LANGUAGE plpgsql;

-- Prueba: Ver categorías donde tengo más de $500 invertidos
SELECT * FROM fn_categorias_alto_valor(500);
select * from  vista_inventario_detallado_kpi
SELECT * FROM fn_reporte_bajo_stock(905);

select * from tipo_material
select * from material_tratamiento
select * from usuario_empleado
-------------------------------------------------------------------------------------------------------------------------------------
--PACIENTE
select * from paciente
select * from tipo_material
select * from material_tratamiento

CREATE OR REPLACE FUNCTION fn_verificar_disponibilidad_cita()
RETURNS TRIGGER AS $$
DECLARE
    v_citas_existentes INTEGER;
    v_id_dentista_nuevo INTEGER;
BEGIN
    -- 1. Obtenemos el ID del dentista que se está intentando asignar en la tabla intermedia
    -- NOTA: Este trigger se dispara en 'Usuario_Empleados_Cita', no en 'Cita', 
    -- porque ahí es donde sabemos QUÉ dentista es.
    
    IF NEW.tipo_empleado = 'Dentista' THEN
        
        -- Buscamos si ESTE dentista (NEW.id_usuario) ya tiene una cita activa
        -- en la MISMA fecha y MISMA hora que la cita que se está ligando (NEW.id_cita)
        SELECT COUNT(*) INTO v_citas_existentes
        FROM Cita c
        JOIN Usuario_Empleados_Cita uec ON c.id_cita = uec.id_cita
        WHERE uec.id_usuario = NEW.id_usuario -- El mismo dentista
          AND c.fecha_hora = (SELECT fecha_hora FROM Cita WHERE id_cita = NEW.id_cita) -- Misma fecha
          AND c.hora = (SELECT hora FROM Cita WHERE id_cita = NEW.id_cita) -- Misma hora
          AND c.estado_cita NOT IN ('Cancelada', 'No asistio') -- Ignorar canceladas
          AND c.id_cita <> NEW.id_cita; -- Ignorarse a sí misma (por si es edición)

        IF v_citas_existentes > 0 THEN
            RAISE EXCEPTION 'El Dentista seleccionado ya tiene una cita agendada en esa fecha y hora.';
        END IF;

    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- TRIGGER QUE SE EJECUTA AL ASIGNAR EL DENTISTA
CREATE TRIGGER tr_verificar_disponibilidad_dentista
BEFORE INSERT OR UPDATE ON Usuario_Empleados_Cita
FOR EACH ROW
EXECUTE FUNCTION fn_verificar_disponibilidad_cita();


DROP INDEX IF EXISTS idx_un_paciente_por_dia;
-- 2. Creamos la NUEVA restricción "Lógica"
-- Regla: El mismo paciente NO puede tener dos citas activas en la misma FECHA y HORA exacta.
CREATE UNIQUE INDEX idx_paciente_un_lugar_a_la_vez 
ON Cita (id_paciente, fecha_hora, hora) 
WHERE estado_cita NOT IN ('Cancelada', 'No asistio');

------------------
select * from cita
select * from detalle_costo
select * from deuda
select * from metodo_pago
select * from pago

-- Muestra solo los horarios que YA están tomados para evitar empalmes.

CREATE OR REPLACE VIEW vista_agenda_ocupada AS
SELECT 
    ue.id_usuario AS id_dentista,
    ue.nombres || ' ' || ue.apellidoPat AS nombre_dentista,
    c.fecha_hora AS fecha,
    c.hora,
    c.estado_cita,
    p.nombrespaciente || ' ' || p.apellidopat AS paciente_ocupante
FROM Usuario_Empleado ue
JOIN Usuario_Empleados_Cita uec ON ue.id_usuario = uec.id_usuario
JOIN Cita c ON uec.id_cita = c.id_cita
JOIN Paciente p ON c.id_paciente = p.id_paciente
WHERE 
    uec.tipo_empleado = 'Dentista'
    AND c.estado_cita NOT IN ('Cancelada', 'No asistio') -- Solo lo que realmente ocupa espacio
ORDER BY 
    c.fecha_hora DESC, c.hora ASC;

-- PRUEBA DE CONSULTA:
SELECT * FROM vista_agenda_ocupada WHERE id_dentista = 2;

select * from usuario_empleados_cita


CREATE OR REPLACE VIEW vista_agenda_ocupada AS
SELECT 
    ue.id_usuario AS id_dentista,
    ue.nombres || ' ' || ue.apellidoPat AS nombre_dentista,
    c.fecha_hora AS fecha,
    c.hora,
    c.estado_cita,
    p.nombrespaciente || ' ' || p.apellidopat AS paciente_ocupante
FROM Usuario_Empleado ue
JOIN Usuario_Empleados_Cita uec ON ue.id_usuario = uec.id_usuario
JOIN Cita c ON uec.id_cita = c.id_cita
JOIN Paciente p ON c.id_paciente = p.id_paciente
WHERE 
    uec.tipo_empleado = 'Dentista'
    AND c.estado_cita NOT IN ('Cancelada', 'No asistio') -- Solo lo que realmente ocupa espacio
ORDER BY 
    c.fecha_hora DESC, c.hora ASC;

-- PRUEBA DE CONSULTA:
-- SELECT * FROM vista_agenda_ocupada WHERE id_dentista = 2;


-- VISTA DEBUG: CITAS Y EMPLEADOS
-- Muestra la relación completa de quién atendió qué cita y en qué puesto.
CREATE OR REPLACE VIEW vista_debug_citas_empleados AS
SELECT 
    c.id_cita,
    c.fecha_hora AS fecha,
    c.hora,
    c.estado_cita,
    c.descripcion,
    -- Concatenamos nombre del empleado
    ue.nombres || ' ' || ue.apellidoPat||ue.apellidoMat AS nombre_empleado,
    -- Mostramos el rol específico que tuvo en esa cita
    uec.tipo_empleado AS puesto_asignado
FROM Cita c
JOIN Usuario_Empleados_Cita uec ON c.id_cita = uec.id_cita
JOIN Usuario_Empleado ue ON uec.id_usuario = ue.id_usuario
ORDER BY 
    c.fecha_hora DESC, c.id_cita ASC;

-- PRUEBA DE CONSULTA PARA DEBUG:
SELECT * FROM vista_debug_citas_empleados;
SELECT * FROM usuario_empleados_cita;
select * from usuario_empleado
select * from cita 
alter COLUMN from cita where fecha_hora='2026-01-'


-- FUNCIÓN: Detalle de Deudas Históricas (Devuelve JSON)
CREATE OR REPLACE FUNCTION fn_obtener_detalle_deudas_historicas(p_id_paciente INTEGER)
RETURNS JSON AS $$
DECLARE
    v_resultado JSON;
BEGIN
    SELECT json_agg(
        json_build_object(
            'id_cita', c.id_cita,
            'fecha', c.fecha_hora,
            'saldo', d.saldo_pendiente,
            'tratamientos', (
                -- Subconsulta para concatenar los tratamientos de ESA cita
                SELECT STRING_AGG(t.nombre, ', ')
                FROM Detalle_Costo dc
                JOIN Tratamiento t ON dc.id_tipo_tratamiento = t.id_tipo_tratamiento
                WHERE dc.id_cita = c.id_cita
            )
        ) ORDER BY c.fecha_hora DESC
    ) INTO v_resultado
    FROM Cita c
    JOIN Deuda d ON c.id_cita = d.id_cita
    WHERE c.id_paciente = p_id_paciente
      AND d.saldo_pendiente > 0;

    -- Si no hay deudas, devolver array vacío en lugar de NULL
    RETURN COALESCE(v_resultado, '[]'::json);
END;
$$ LANGUAGE plpgsql;

-- PRUEBA:
select * from cita
SELECT fn_obtener_detalle_deudas_historicas(6);
SELECT * FROM DEUDA
select * from cita where id_cita=101
select * from paciente where id_paciente=8

UPDATE cita 
SET fecha_hora = '2025-12-14'
WHERE id_cita = 66
  AND id_paciente = 14;
  
select * from cita where estado_cita='Atendida'

SELECT 
    c.id_cita, 
    c.fecha_hora, 
    c.hora, 
    c.estado_cita, 
    c.descripcion,
    p.nombrespaciente || ' ' || p.apellidopat || ' ' || COALESCE(p.apellidomat, '') AS nombre_paciente,
    p.telefono,
    ue.id_usuario AS id_dentista,
    ue.nombres || ' ' || ue.apellidoPat AS nombre_dentista
FROM Cita c
JOIN Paciente p 
    ON c.id_paciente = p.id_paciente
LEFT JOIN Usuario_Empleados_Cita uec 
    ON c.id_cita = uec.id_cita 
   AND uec.tipo_empleado = 'Dentista'
LEFT JOIN Usuario_Empleado ue 
    ON uec.id_usuario = ue.id_usuario
WHERE ue.nombres = 'JUAN';
SELECT * FROM USUARIO_EMPLEADO


 select * from material_tratamiento
 select * from tipo_material
select * from cita
 select * from deuda where estado='Pagada'
select * from paciente

 DELETE  FROM CITA WHERE FECHA_hora='2025-12-01' and nombre


DELETE FROM Cita
WHERE fecha_hora::date = '2025-12-01'
  AND id_paciente = 1;

SELECT * FROM ESTUDIO 

select * from paciente

DELETE FROM derivacion WHERE id_paciente=10

WHERE fecha_hora::date = '2025-12-01'
  AND id_paciente = 1;

DELETE FROM HISTORIAL_CLINICO WHERE ID_CITA=53

DELETE FROM Usuario_Empleados_Cita
WHERE id_cita = 53;

DELETE FROM deuda
WHERE id_cita = 53;

DELETE FROM PAGO
WHERE id_cita = 53



DELETE FROM DETALLE_COSTO
WHERE id_cita = 53;

DELETE FROM cita
WHERE id_cita = 53;

--


-- 1. Borrar tablas hijas (dependencias) primero
DELETE FROM Detalle_Costo WHERE id_cita BETWEEN 200 AND 299;
DELETE FROM Pago WHERE id_cita BETWEEN 200 AND 299; -- Esto puede requerir borrar Detalle primero si hay FK, pero aquí Detalle apunta a Pago.
-- Si Detalle apunta a Pago, primero borramos Detalle, luego Pago. (El orden arriba es correcto).

DELETE FROM Deuda WHERE id_cita BETWEEN 200 AND 299;
DELETE FROM Historial_Clinico WHERE id_cita BETWEEN 200 AND 299;
DELETE FROM Usuario_Empleados_Cita WHERE id_cita BETWEEN 200 AND 299;

-- Borrar derivaciones de prueba creadas en fechas de septiembre (por si acaso)
DELETE FROM Derivacion WHERE fecha BETWEEN '2025-09-01' AND '2025-09-30';

-- 2. Borrar la tabla padre (Cita) al final
DELETE FROM Cita WHERE id_cita BETWEEN 200 AND 299;


-- ==============================================================================
-- 1. INSERTAR CITAS (Septiembre 1 - Septiembre 30)
-- ==============================================================================

INSERT INTO Cita (id_cita, fecha_hora, hora, descripcion, estado_cita, id_paciente) VALUES
-- SEMANA 1: Inicio fuerte
(200, '2025-09-01', '09:00:00', 'Limpieza profunda semestral', 'Atendida', 1), -- Álvaro
(201, '2025-09-01', '11:00:00', 'Dolor en muela superior', 'Atendida', 2), -- María
(202, '2025-09-02', '10:00:00', 'Valoración de Ortodoncia', 'Confirmada', 3), -- José
(203, '2025-09-02', '16:00:00', 'Blanqueamiento sesión 1', 'Cancelada', 4), -- Lucía (Canceló)

-- SEMANA 2: Casos clínicos
(204, '2025-09-08', '12:00:00', 'Ajuste de brackets', 'Atendida', 8), -- Sofía
(205, '2025-09-09', '09:00:00', 'Extracción de premolar', 'Atendida', 5), -- Óscar
(206, '2025-09-10', '17:00:00', 'Revisión general', 'No asistio', 6), -- Camila

-- SEMANA 3: Quincena (Pagos y Deudas)
(207, '2025-09-15', '10:00:00', 'Resina estética frontal', 'Atendida', 7), -- Estéban
(208, '2025-09-17', '11:30:00', 'Limpieza infantil', 'Atendida', 11), -- Isabella (Hija?)
(209, '2025-09-18', '16:00:00', 'Entrega de guarda nocturna', 'Pendiente', 9), -- Andrés

-- SEMANA 4: Cierre de mes y casos complejos
(210, '2025-09-22', '09:00:00', 'Inicio tratamiento conductos', 'Atendida', 10), -- Valentina (Caso complejo)
(211, '2025-09-25', '13:00:00', 'Limpieza rápida', 'Atendida', 12), -- Mateo
(212, '2025-09-29', '10:00:00', 'Revisión post-extracción', 'Agendada', 5); -- Óscar (Seguimiento)


-- ==============================================================================
-- 2. ASIGNACIÓN DE EMPLEADOS (Dentistas y Recepción)
-- Dr. Juan (ID 2) y Dra. Diana (ID 4) se alternan para no empalmarse.
-- Recepcionista Carlos (ID 1) atiende a todos.
-- ==============================================================================

INSERT INTO Usuario_Empleados_Cita (id_cita, id_usuario, tipo_empleado) VALUES
-- Cita 200: Dr. Juan
(200, 2, 'Dentista'), (200, 1, 'Recepcion'),
-- Cita 201: Dra. Diana
(201, 4, 'Dentista'), (201, 1, 'Recepcion'),
-- Cita 202: Dr. Juan
(202, 2, 'Dentista'), (202, 1, 'Recepcion'),
-- Cita 203: Dra. Diana (Aunque canceló, estaba asignada)
(203, 4, 'Dentista'), (203, 1, 'Recepcion'),
-- Cita 204: Dra. Diana (Ortodoncia)
(204, 4, 'Dentista'), (204, 1, 'Recepcion'),
-- Cita 205: Dr. Juan (Cirugía)
(205, 2, 'Dentista'), (205, 1, 'Recepcion'),
-- Cita 206: Dr. Juan
(206, 2, 'Dentista'), (206, 1, 'Recepcion'),
-- Cita 207: Dra. Diana (Estética)
(207, 4, 'Dentista'), (207, 1, 'Recepcion'),
-- Cita 208: Dr. Juan
(208, 2, 'Dentista'), (208, 1, 'Recepcion'),
-- Cita 209: Dra. Diana
(209, 4, 'Dentista'), (209, 1, 'Recepcion'),
-- Cita 210: Dr. Juan (Endodoncia)
(210, 2, 'Dentista'), (210, 1, 'Recepcion'),
-- Cita 211: Dra. Diana
(211, 4, 'Dentista'), (211, 1, 'Recepcion'),
-- Cita 212: Dr. Juan
(212, 2, 'Dentista'), (212, 1, 'Recepcion');


-- ==============================================================================
-- 3. PAGOS Y DEUDAS (Aquí está el dinero)
-- ==============================================================================

-- Cita 200 (Álvaro): Pagó todo ($500) en Efectivo.
INSERT INTO Pago (cantidadPagada, fecha_hora, id_cita, metodoPagoid_metodopago) VALUES (500, '2025-09-01 09:30:00', 200, 1);
INSERT INTO Deuda (monto_total, monto_pagado, saldo_pendiente, id_cita, estado) VALUES (500, 500, 0, 200, 'Pagada');

-- Cita 201 (María): Tratamiento caro ($600), solo traía $200. DEBE DINERO.
INSERT INTO Pago (cantidadPagada, fecha_hora, id_cita, metodoPagoid_metodopago) VALUES (200, '2025-09-01 11:45:00', 201, 1);
INSERT INTO Deuda (monto_total, monto_pagado, saldo_pendiente, id_cita, estado) VALUES (600, 200, 400, 201, 'Abono');

-- Cita 204 (Sofía): Ortodoncia ($1500), pagó por Transferencia.
INSERT INTO Pago (cantidadPagada, fecha_hora, id_cita, metodoPagoid_metodopago) VALUES (1500, '2025-09-08 12:40:00', 204, 2);
INSERT INTO Deuda (monto_total, monto_pagado, saldo_pendiente, id_cita, estado) VALUES (1500, 1500, 0, 204, 'Pagada');

-- Cita 205 (Óscar): Extracción ($800). Pagó todo.
INSERT INTO Pago (cantidadPagada, fecha_hora, id_cita, metodoPagoid_metodopago) VALUES (800, '2025-09-09 10:00:00', 205, 1);
INSERT INTO Deuda (monto_total, monto_pagado, saldo_pendiente, id_cita, estado) VALUES (800, 800, 0, 205, 'Pagada');

-- Cita 207 (Estéban): Resina ($600). Se le olvidó la cartera, no pagó nada. DEUDA TOTAL.
-- (No hay insert en Pago porque no pagó)
INSERT INTO Deuda (monto_total, monto_pagado, saldo_pendiente, id_cita, estado) VALUES (600, 0, 600, 207, 'Pendiente a pagar');

-- Cita 208 (Isabella): Limpieza infantil ($500). Pagó completo.
INSERT INTO Pago (cantidadPagada, fecha_hora, id_cita, metodoPagoid_metodopago) VALUES (500, '2025-09-17 12:00:00', 208, 1);
INSERT INTO Deuda (monto_total, monto_pagado, saldo_pendiente, id_cita, estado) VALUES (500, 500, 0, 208, 'Pagada');

-- Cita 210 (Valentina): Endodoncia inicial. Dejó un abono grande.
INSERT INTO Pago (cantidadPagada, fecha_hora, id_cita, metodoPagoid_metodopago) VALUES (1000, '2025-09-22 10:30:00', 210, 2);
-- Se asume un costo mayor o parcial, aquí registramos lo que se cobró vs lo que costaba ese día.
INSERT INTO Deuda (monto_total, monto_pagado, saldo_pendiente, id_cita, estado) VALUES (1000, 1000, 0, 210, 'Pagada');

-- Cita 211 (Mateo): Limpieza rápida ($500). Pagó completo.
INSERT INTO Pago (cantidadPagada, fecha_hora, id_cita, metodoPagoid_metodopago) VALUES (500, '2025-09-25 13:30:00', 211, 1);
INSERT INTO Deuda (monto_total, monto_pagado, saldo_pendiente, id_cita, estado) VALUES (500, 500, 0, 211, 'Pagada');


-- ==============================================================================
-- 4. DETALLE DE COSTOS (Qué se hizo y qué se usó - UN TRATAMIENTO POR CITA)
-- ==============================================================================

-- Cita 200: Limpieza (ID Trat 1) usando Kit Limpieza (ID Mat 5)
INSERT INTO Detalle_Costo (cantidad, subTotal, id_cita, id_tipo_tratamiento, id_tipo_material, id_pago) 
VALUES (1, 500, 200, 1, 5, (SELECT idPago FROM Pago WHERE id_cita = 200));

-- Cita 201: Resina (ID Trat 4) usando Resina A2 (ID Mat 2)
INSERT INTO Detalle_Costo (cantidad, subTotal, id_cita, id_tipo_tratamiento, id_tipo_material, id_pago) 
VALUES (1, 600, 201, 4, 2, (SELECT idPago FROM Pago WHERE id_cita = 201));

-- Cita 204: Ortodoncia (ID Trat 2) usando Material Ortodoncia (ID Mat 3)
INSERT INTO Detalle_Costo (cantidad, subTotal, id_cita, id_tipo_tratamiento, id_tipo_material, id_pago) 
VALUES (1, 1500, 204, 2, 3, (SELECT idPago FROM Pago WHERE id_cita = 204));

-- Cita 205: Extracción (ID Trat 3) usando Anestesia (ID Mat 1)
INSERT INTO Detalle_Costo (cantidad, subTotal, id_cita, id_tipo_tratamiento, id_tipo_material, id_pago) 
VALUES (1, 800, 205, 3, 1, (SELECT idPago FROM Pago WHERE id_cita = 205));

-- Cita 207: Resina (ID Trat 4) usando Resina A2 (ID Mat 2). SIN PAGO ASOCIADO (id_pago NULL).
INSERT INTO Detalle_Costo (cantidad, subTotal, id_cita, id_tipo_tratamiento, id_tipo_material, id_pago) 
VALUES (1, 600, 207, 4, 2, NULL);

-- Cita 208: Limpieza (ID Trat 1) usando Kit Limpieza (ID Mat 5).
INSERT INTO Detalle_Costo (cantidad, subTotal, id_cita, id_tipo_tratamiento, id_tipo_material, id_pago) 
VALUES (1, 500, 208, 1, 5, (SELECT idPago FROM Pago WHERE id_cita = 208));

-- Cita 210: Tratamiento complejo. Usaremos Extracción (ID 3) como base de costo + extra manual o similar.
-- Usaremos ID 3 (Extracción $800) pero en la deuda reflejamos $1000. Ajustamos el subtotal aquí a $1000.
INSERT INTO Detalle_Costo (cantidad, subTotal, id_cita, id_tipo_tratamiento, id_tipo_material, id_pago) 
VALUES (1, 1000, 210, 3, 1, (SELECT idPago FROM Pago WHERE id_cita = 210));

-- Cita 211: Limpieza (ID Trat 1).
INSERT INTO Detalle_Costo (cantidad, subTotal, id_cita, id_tipo_tratamiento, id_tipo_material, id_pago) 
VALUES (1, 500, 211, 1, 5, (SELECT idPago FROM Pago WHERE id_cita = 211));


-- ==============================================================================
-- 5. HISTORIAL CLÍNICO (Solo para las citas 'Atendida' - SIEMPRE CON DESCRIPCIÓN)
-- ==============================================================================

INSERT INTO Historial_Clinico (alergias, enfermedades, avanceTratamiento, fecha, id_cita) VALUES
('Polvo', 'Ninguna', 'Paciente acude a limpieza semestral. Poca presencia de sarro.', '2025-09-01', 200),
('Ninguna', 'Hipertensión controlada', 'Dolor agudo en pieza 16. Se coloca resina profunda. Monitorear sensibilidad.', '2025-09-01', 201),
('Látex', 'Ninguna', 'Cambio de arco y ligas. Higiene mejorable.', '2025-09-08', 204),
('Ninguna', 'Ninguna', 'Extracción de premolar 44 por indicación ortodóntica. Sin complicaciones.', '2025-09-09', 205),
('Penicilina', 'Diabetes', 'Restauración estética en incisivo central. Paciente satisfecho.', '2025-09-15', 207),
('Ninguna', 'Ninguna', 'Paciente infantil muy cooperador. Se realiza profilaxis completa y aplicación de flúor tópico.', '2025-09-17', 208),
('Ninguna', 'Ninguna', 'Apertura de cámara pulpar por dolor intenso. Se deja medicación intraconducto.', '2025-09-22', 210),
('Ninguna', 'Asma', 'Limpieza dental de rutina. Se detecta inicio de gingivitis localizada, se instruye técnica de cepillado.', '2025-09-25', 211);


-- ==============================================================================
-- 6. DERIVACIÓN (El caso especial)
-- Valentina (Cita 210) tiene un conducto calcificado y se deriva a especialista externo.
-- ==============================================================================

INSERT INTO Derivacion (fecha, nombreDentista, motivo, especialidadDentista, apellidoPatDentista, apellidoMatDentista, id_paciente, fecha_hora) 
VALUES ('2025-09-22', 'Ernesto', 'Conductos calcificados microscopía', 'Endodoncista', 'Zedillo', 'P.', 10, '2025-09-22 10:00:00');

select * from cita
select * from material_tratamiento
select * from tipo_material


--
-- *** 1. FUNCION DE ALTA (fn_crear_material) - SOLO 5 PARÁMETROS ***
CREATE OR REPLACE FUNCTION fn_crear_material(
    p_nombre VARCHAR,
    p_costoUnitario INTEGER,
    p_stock INTEGER,
    p_cantidad INTEGER,
    p_id_tipo_material INTEGER
)
RETURNS INTEGER AS $$
DECLARE
    v_new_id INTEGER;
BEGIN
    INSERT INTO Material_Tratamiento (
        nombre, 
        costoUnitario, 
        stock, 
        cantidad, 
        id_tipo_material
    )
    VALUES (
        p_nombre,
        p_costoUnitario,
        p_stock,
        p_cantidad,
        p_id_tipo_material
    )
    RETURNING id_material INTO v_new_id;

    RETURN v_new_id;
END;
$$ LANGUAGE plpgsql;

-- *** 2. FUNCION DE UPDATE (fn_actualizar_material) - SOLO 6 PARÁMETROS ***
CREATE OR REPLACE FUNCTION fn_actualizar_material(
    p_id_material INTEGER,
    p_nombre VARCHAR,
    p_costoUnitario INTEGER,
    p_stock INTEGER,
    p_cantidad INTEGER,
    p_id_tipo_material INTEGER
)
RETURNS VARCHAR AS $$
BEGIN
    UPDATE Material_Tratamiento
    SET
        nombre = p_nombre,
        costounitario = p_costoUnitario,
        stock = p_stock,
        cantidad = p_cantidad,
        id_tipo_material = p_id_tipo_material
    WHERE
        id_material = p_id_material;

    IF FOUND THEN
        RETURN 'Material ' || p_id_material || ' actualizado exitosamente.';
    ELSE
        RETURN 'ERROR: Material ' || p_id_material || ' no encontrado.';
    END IF;
EXCEPTION
    WHEN foreign_key_violation THEN
        RETURN 'ERROR: El Tipo de Material (ID ' || p_id_tipo_material || ') no existe.';
    WHEN others THEN
        RETURN 'ERROR: Error al actualizar el material.';
END;
$$ LANGUAGE plpgsql;

-- *** 3. FUNCION BAJA (fn_eliminar_material) - SIN CAMBIOS, SOLO PARA ASEGURAR ***
CREATE OR REPLACE FUNCTION fn_eliminar_material(p_id INTEGER)
RETURNS TEXT AS $$
BEGIN
    DELETE FROM Material_Tratamiento WHERE id_material = p_id;
    IF NOT FOUND THEN
        RETURN 'ERROR: Material con ID ' || p_id || ' no encontrado.';
    ELSE
        RETURN 'Material eliminado exitosamente.';
    END IF;
END;
$$ LANGUAGE plpgsql;

-- *** 4. FUNCION BUSCAR (fn_buscar_material) - SIN CAMBIOS LÓGICOS ***
-- Esta función sigue usando unaccent, el cual debe ser instalado (Paso 1A).
CREATE OR REPLACE FUNCTION fn_buscar_material(p_term TEXT)
RETURNS SETOF Material_Tratamiento AS $$
DECLARE
    v_id INTEGER;
    v_term_normalized TEXT;
BEGIN
    v_term_normalized := lower(unaccent(p_term));
    BEGIN
        v_id := p_term::INTEGER;
    EXCEPTION
        WHEN invalid_text_representation THEN
            v_id := NULL;
    END;

    IF v_id IS NOT NULL THEN
        RETURN QUERY
        SELECT *
        FROM Material_Tratamiento
        WHERE id_material = v_id
            OR id_tipo_material = v_id
            OR lower(unaccent(nombre)) LIKE '%' || v_term_normalized || '%';
    ELSE
        RETURN QUERY
        SELECT *
        FROM Material_Tratamiento
        WHERE lower(unaccent(nombre)) LIKE '%' || v_term_normalized || '%';
    END IF;
END;
$$ LANGUAGE plpgsql;
