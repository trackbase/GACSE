CREATE PROCEDURE sp_ObtenerAgendaDiariaMedico
    @MedicoId INT,
    @Fecha DATE
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        c.Id AS CitaId,
        CAST(c.FechaHoraInicio AS TIME) AS HoraInicio,
        CAST(c.FechaHoraFin AS TIME) AS HoraFin,
        p.Id AS PacienteId,
        p.Nombre AS NombrePaciente,
        p.Telefono AS TelefonoPaciente,
        c.Estado,
        c.Motivo
    FROM Citas c
    INNER JOIN Pacientes p ON c.PacienteId = p.Id
    WHERE c.MedicoId = @MedicoId
      -- Casteamos a DATE para ignorar la hora y buscar en todo el día
      AND CAST(c.FechaHoraInicio AS DATE) = @Fecha 
    ORDER BY c.FechaHoraInicio ASC;
END;
GO