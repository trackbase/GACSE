CREATE PROCEDURE sp_ValidarDisponibilidadMedico
    @MedicoId INT,
    @FechaHoraInicio DATETIME2,
    @EsValido BIT OUTPUT,
    @MensajeError NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Inicializar variables de salida
    SET @EsValido = 1;
    SET @MensajeError = '';

    -- 1. Validar Regla 4: Sin citas pasadas
    IF @FechaHoraInicio <= GETDATE()
    BEGIN
        SET @EsValido = 0;
        SET @MensajeError = 'No se pueden agendar citas en fechas u horas pasadas.';
        RETURN;
    END

    -- Variables para cálculos
    DECLARE @DuracionMinutos INT;
    DECLARE @FechaHoraFin DATETIME2;
    DECLARE @DiaSemana INT;
    DECLARE @HoraInicioSolicitada TIME = CAST(@FechaHoraInicio AS TIME);
    DECLARE @HoraFinSolicitada TIME;
    
    -- Determinar el día de la semana (1 = Lunes, ..., 7 = Domingo) adaptado para SQL Server
    SET @DiaSemana = (DATEPART(WEEKDAY, @FechaHoraInicio) + @@DATEFIRST - 2) % 7 + 1;

    -- 2. Validar Regla 2: Obtener la duración según la especialidad del médico
    SELECT @DuracionMinutos = e.DuracionMinutos
    FROM Medicos m
    INNER JOIN Especialidades e ON m.EspecialidadId = e.Id
    WHERE m.Id = @MedicoId;

    IF @DuracionMinutos IS NULL
    BEGIN
        SET @EsValido = 0;
        SET @MensajeError = 'El médico especificado no existe o no tiene una especialidad asignada.';
        RETURN;
    END

    -- Calcular la hora de fin de la consulta
    SET @FechaHoraFin = DATEADD(MINUTE, @DuracionMinutos, @FechaHoraInicio);
    SET @HoraFinSolicitada = CAST(@FechaHoraFin AS TIME);

    -- 3. Validar Regla 3: Horario del médico
    DECLARE @HoraInicioTurno TIME;
    DECLARE @HoraFinTurno TIME;

    SELECT @HoraInicioTurno = HoraInicio, @HoraFinTurno = HoraFin
    FROM HorariosMedico
    WHERE MedicoId = @MedicoId AND DiaSemana = @DiaSemana;

    IF @HoraInicioTurno IS NULL -- No trabaja ese día
       OR @HoraInicioSolicitada < @HoraInicioTurno 
       OR @HoraFinSolicitada > @HoraFinTurno
    BEGIN
        SET @EsValido = 0;
        SET @MensajeError = 'El horario solicitado está fuera del turno de trabajo del médico para este día.';
        RETURN;
    END

    -- 4. Validar Regla 1: Sin citas simultáneas (Evitar traslapes)
    IF EXISTS (
        SELECT 1 
        FROM Citas 
        WHERE MedicoId = @MedicoId 
          AND Estado = 'Agendada'
          AND (
              (@FechaHoraInicio >= FechaHoraInicio AND @FechaHoraInicio < FechaHoraFin) OR -- Inicia durante otra cita
              (@FechaHoraFin > FechaHoraInicio AND @FechaHoraFin <= FechaHoraFin) OR       -- Termina durante otra cita
              (@FechaHoraInicio <= FechaHoraInicio AND @FechaHoraFin >= FechaHoraFin)      -- Envuelve por completo a otra cita
          )
    )
    BEGIN
        SET @EsValido = 0;
        SET @MensajeError = 'El médico ya tiene una cita agendada que se empalma con este horario.';
        RETURN;
    END

END;
GO