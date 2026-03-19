-- ====================================================================
-- Script de Creación de Base de Datos - Mini-Agenda Médica
-- ====================================================================

CREATE DATABASE GacseAgendaMedica;
GO

USE GacseAgendaMedica;
GO

-- 1. Tabla de Especialidades
-- Resuelve la Regla 2: Duración por especialidad
CREATE TABLE Especialidades (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Nombre NVARCHAR(100) NOT NULL,
    DuracionMinutos INT NOT NULL
);

-- 2. Tabla de Médicos
CREATE TABLE Medicos (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Nombre NVARCHAR(200) NOT NULL,
    EspecialidadId INT NOT NULL,
    CONSTRAINT FK_Medicos_Especialidades FOREIGN KEY (EspecialidadId) REFERENCES Especialidades(Id)
);

-- 3. Tabla de Horarios del Médico
-- Resuelve la Regla 3: Horario del médico y horarios de consulta por día
CREATE TABLE HorariosMedico (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    MedicoId INT NOT NULL,
    DiaSemana INT NOT NULL, -- 1 = Lunes, 2 = Martes, ..., 7 = Domingo
    HoraInicio TIME NOT NULL,
    HoraFin TIME NOT NULL,
    CONSTRAINT FK_HorariosMedico_Medicos FOREIGN KEY (MedicoId) REFERENCES Medicos(Id),
    CONSTRAINT CHK_DiaSemana CHECK (DiaSemana BETWEEN 1 AND 7),
    CONSTRAINT CHK_Horas CHECK (HoraInicio < HoraFin)
);

-- 4. Tabla de Pacientes
CREATE TABLE Pacientes (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Nombre NVARCHAR(200) NOT NULL,
    FechaNacimiento DATE NOT NULL,
    Telefono NVARCHAR(20) NULL,
    Correo NVARCHAR(100) NULL
);

-- 5. Tabla de Citas
-- El núcleo transaccional. Guarda FechaHoraInicio y FechaHoraFin para facilitar 
-- la validación de la Regla 1 (Sin citas simultáneas).
CREATE TABLE Citas (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    MedicoId INT NOT NULL,
    PacienteId INT NOT NULL,
    FechaHoraInicio DATETIME2 NOT NULL,
    FechaHoraFin DATETIME2 NOT NULL,
    Estado NVARCHAR(20) NOT NULL DEFAULT 'Agendada', -- 'Agendada', 'Cancelada', 'Completada'
    Motivo NVARCHAR(500) NOT NULL,
    MotivoCancelacion NVARCHAR(500) NULL,
    FechaCreacion DATETIME2 NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Citas_Medicos FOREIGN KEY (MedicoId) REFERENCES Medicos(Id),
    CONSTRAINT FK_Citas_Pacientes FOREIGN KEY (PacienteId) REFERENCES Pacientes(Id),
    CONSTRAINT CHK_EstadoCita CHECK (Estado IN ('Agendada', 'Cancelada', 'Completada')),
    CONSTRAINT CHK_FechasCita CHECK (FechaHoraInicio < FechaHoraFin)
);
GO

-- ====================================================================
-- Inserción de Datos de Ejemplo (Catálogos Iniciales)
-- ====================================================================

-- Insertar Especialidades con las duraciones exactas de la prueba
INSERT INTO Especialidades (Nombre, DuracionMinutos)
VALUES 
    ('Medicina General', 20),
    ('Cardiología', 30),
    ('Cirugía', 45),
    ('Pediatría', 20),
    ('Ginecología', 30);

-- Insertar Médicos de prueba
INSERT INTO Medicos (Nombre, EspecialidadId)
VALUES 
    ('Dr. Roberto Gómez', 1), -- Medicina General (20 min)
    ('Dra. Ana Silva', 2),    -- Cardiología (30 min)
    ('Dr. Carlos Ruiz', 3);   -- Cirugía (45 min)

-- Insertar Horarios de prueba (Ej: Dr. Roberto Gómez atiende Lunes y Martes de 8am a 2pm)
INSERT INTO HorariosMedico (MedicoId, DiaSemana, HoraInicio, HoraFin)
VALUES 
    (1, 1, '08:00', '14:00'), -- Lunes
    (1, 2, '09:00', '15:00'), -- Martes
    (2, 3, '10:00', '18:00'); -- Miércoles (Dra. Ana Silva)

-- Insertar un Paciente de prueba
INSERT INTO Pacientes (Nombre, FechaNacimiento, Telefono, Correo)
VALUES 
    ('Juan Pérez', '1985-06-15', '555-1234', 'juan.perez@email.com'),
    ('María López', '1992-09-21', '555-5678', 'maria.lopez@email.com');
GO