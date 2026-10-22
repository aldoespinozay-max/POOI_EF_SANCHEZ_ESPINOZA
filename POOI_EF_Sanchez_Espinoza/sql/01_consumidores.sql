IF DB_ID('ExamenFinal') IS NULL
    CREATE DATABASE ExamenFinal;
GO
USE ExamenFinal;
GO

-- tabla mínima para que funcione la referencia solicitada si aún no existe
IF OBJECT_ID('dbo.tb_paises', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.tb_paises (
        idpais char(3) PRIMARY KEY,
        nompais varchar(40) NOT NULL
    );
END;
GO

IF OBJECT_ID('dbo.tb_consumidor', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.tb_consumidor (
        dnicont char(8) PRIMARY KEY,
        nomcont varchar(40) NOT NULL,
        apecont varchar(40) NOT NULL,
        emailcont varchar(250),
        idpais char(3) REFERENCES dbo.tb_paises(idpais)
    );
END;
GO

-- permite varios consumidores sin correo y mantiene únicos los correos ingresados
DECLARE @restriccion sysname;
SELECT TOP 1 @restriccion = kc.name
FROM sys.key_constraints kc
INNER JOIN sys.index_columns ic
    ON ic.object_id = kc.parent_object_id
   AND ic.index_id = kc.unique_index_id
INNER JOIN sys.columns c
    ON c.object_id = ic.object_id
   AND c.column_id = ic.column_id
WHERE kc.parent_object_id = OBJECT_ID('dbo.tb_consumidor')
  AND kc.type = 'UQ'
  AND c.name = 'emailcont'
  AND ic.key_ordinal = 1;
IF @restriccion IS NOT NULL
BEGIN
    DECLARE @sentencia nvarchar(500);
    SET @sentencia = N'ALTER TABLE dbo.tb_consumidor DROP CONSTRAINT ' + QUOTENAME(@restriccion);
    EXEC sp_executesql @sentencia;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID('dbo.tb_consumidor')
      AND name = 'UX_tb_consumidor_emailcont'
)
BEGIN
    CREATE UNIQUE INDEX UX_tb_consumidor_emailcont
    ON dbo.tb_consumidor(emailcont)
    WHERE emailcont IS NOT NULL;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_agrega_consumidor
    @dnicont char(8),
    @nomcont varchar(40),
    @apecont varchar(40),
    @emailcont varchar(250),
    @idpais char(3),
    @mensaje varchar(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    IF @emailcont IS NOT NULL AND LTRIM(RTRIM(@emailcont)) = ''
        SET @emailcont = NULL;
    IF @dnicont IS NULL OR LEN(@dnicont) <> 8 OR @dnicont LIKE '%[^0-9]%'
    BEGIN
        SET @mensaje = 'el dni debe tener 8 dígitos numéricos';
        RETURN;
    END;
    IF @nomcont IS NULL OR LTRIM(RTRIM(@nomcont)) = ''
       OR @apecont IS NULL OR LTRIM(RTRIM(@apecont)) = ''
    BEGIN
        SET @mensaje = 'nombre y apellido son obligatorios';
        RETURN;
    END;
    IF @idpais IS NULL OR LTRIM(RTRIM(@idpais)) = ''
       OR NOT EXISTS (SELECT 1 FROM dbo.tb_paises WHERE idpais = @idpais)
    BEGIN
        SET @mensaje = 'el código de país no existe';
        RETURN;
    END;
    IF EXISTS (SELECT 1 FROM dbo.tb_consumidor WHERE dnicont = @dnicont)
    BEGIN
        SET @mensaje = 'el dni ya está registrado';
        RETURN;
    END;
    IF @emailcont IS NOT NULL
       AND EXISTS (SELECT 1 FROM dbo.tb_consumidor WHERE emailcont = @emailcont)
    BEGIN
        SET @mensaje = 'el correo ya está registrado';
        RETURN;
    END;

    INSERT INTO dbo.tb_consumidor (dnicont, nomcont, apecont, emailcont, idpais)
    VALUES (@dnicont, @nomcont, @apecont, @emailcont, @idpais);
    SET @mensaje = 'consumidor registrado correctamente';
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_eliminar_consumidor
    @dnicont char(8),
    @mensaje varchar(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.tb_consumidor WHERE dnicont = @dnicont)
    BEGIN
        SET @mensaje = 'el consumidor no existe';
        RETURN;
    END;
    DELETE FROM dbo.tb_consumidor WHERE dnicont = @dnicont;
    SET @mensaje = 'consumidor eliminado correctamente';
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_listar_consumidor
AS
BEGIN
    SELECT dnicont, nomcont, apecont, emailcont, idpais
    FROM dbo.tb_consumidor
    ORDER BY apecont, nomcont;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_obtener_consumidor
    @dnicont char(8)
AS
BEGIN
    SELECT dnicont, nomcont, apecont, emailcont, idpais
    FROM dbo.tb_consumidor
    WHERE dnicont = @dnicont;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_actualizar_consumidor
    @dnicont char(8),
    @nomcont varchar(40),
    @apecont varchar(40),
    @emailcont varchar(250),
    @idpais char(3),
    @mensaje varchar(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.tb_consumidor WHERE dnicont = @dnicont)
    BEGIN
        SET @mensaje = 'el consumidor no existe';
        RETURN;
    END;
    IF @nomcont IS NULL OR LTRIM(RTRIM(@nomcont)) = ''
       OR @apecont IS NULL OR LTRIM(RTRIM(@apecont)) = ''
    BEGIN
        SET @mensaje = 'nombre y apellido son obligatorios';
        RETURN;
    END;
    IF @idpais IS NULL OR LTRIM(RTRIM(@idpais)) = ''
       OR NOT EXISTS (SELECT 1 FROM dbo.tb_paises WHERE idpais = @idpais)
    BEGIN
        SET @mensaje = 'el código de país no existe';
        RETURN;
    END;
    IF @emailcont IS NOT NULL
       AND EXISTS (SELECT 1 FROM dbo.tb_consumidor
                   WHERE emailcont = @emailcont AND dnicont <> @dnicont)
    BEGIN
        SET @mensaje = 'el correo ya está registrado';
        RETURN;
    END;

    UPDATE dbo.tb_consumidor
    SET nomcont = @nomcont, apecont = @apecont,
        emailcont = @emailcont, idpais = @idpais
    WHERE dnicont = @dnicont;
    SET @mensaje = 'consumidor actualizado correctamente';
END;
GO
