CREATE PROCEDURE [dbo].[prc_change_double_person]
	@id_person_from integer,
	@id_person_to integer,
	@login VARCHAR(50),
	@result integer OUTPUT
WITH 

EXECUTE AS 'create_table' 
        
        AS

DECLARE @strsql           VARCHAR(200),
        @table_name       VARCHAR(50),
        @column_name      VARCHAR(50),
        @strout           VARCHAR(100),
        @isdelete         BIT

IF EXISTS(
       SELECT *
       FROM   tbl_Persons tp
              INNER JOIN tbl_Documents td
                   ON  td.ID_NatPerson = tp.ID_person
              INNER JOIN loss.tbl_personal_docs tpd
                   ON  td.ID_document = tpd.ID_document
       WHERE  tp.ID_person = @id_person_from
   )
BEGIN
    RAISERROR(
        'Контрагент присутствует в страховом деле, удаление невозможно',
        16,
        1
    )
    RETURN
END

ALTER TABLE loss.tbl_OccurrenceParticipantsCar NOCHECK CONSTRAINT ALL

IF EXISTS(
       SELECT *
       FROM   tbl_Employees te
       WHERE  te.ID_employee = @id_person_from
   )
   AND NOT EXISTS(
           SELECT *
           FROM   tbl_Employees te
           WHERE  te.ID_employee = @id_person_to
       )
    INSERT INTO tbl_Employees
      (
        ID_employee,
        ID_department,
        ID_Appointment,
        IsCurator,
        IsAgentCurator,
        IsDismissed,
        Rodfio
      )
    SELECT @id_person_to,
           ID_department,
           ID_Appointment,
           IsCurator,
           IsAgentCurator,
           IsDismissed,
           Rodfio
    FROM   tbl_Employees te
    WHERE  te.ID_employee = @id_person_from
	
IF EXISTS(
       SELECT *
       FROM   tbl_Logins te
       WHERE  id_employ = @id_person_from
   )
   AND NOT EXISTS(
           SELECT *
           FROM   tbl_Logins te
           WHERE  id_employ = @id_person_to
       )
    INSERT INTO tbl_Logins
      (
        id_employ,
        [login],
        Pwd
      )
    SELECT @id_person_to,
           [login],
           Pwd
    FROM   tbl_Logins te
    WHERE  id_employ = @id_person_from

IF EXISTS(
       SELECT *
       FROM   tbl_Underwriters te
       WHERE  ID_Underwriter = @id_person_from
   )
   AND NOT EXISTS(
           SELECT *
           FROM   tbl_Underwriters te
           WHERE  ID_Underwriter = @id_person_to
       )
    INSERT INTO tbl_Underwriters
      (
        ID_Underwriter,
        PoA_Date,
        PoA_Number
      )
    SELECT @id_person_to,
           PoA_Date,
           PoA_Number
    FROM   tbl_Underwriters te
    WHERE  ID_Underwriter = @id_person_from
	
IF EXISTS(
       SELECT *
       FROM   tbl_Agents
       WHERE  Agent_ID = @id_person_from
   )
   AND NOT EXISTS(
           SELECT *
           FROM   tbl_Agents
           WHERE  Agent_ID = @id_person_to
       )
    INSERT INTO tbl_Agents
      (
        Agent_ID,
        fee_tax
      )
    SELECT @id_person_to,
           fee_tax
    FROM   tbl_Agents
    WHERE  Agent_ID = @id_person_from
	
IF EXISTS(
       SELECT *
       FROM   tbl_ContactPersons
       WHERE  ID_NatPerson = @id_person_from
   )
   AND NOT EXISTS(
           SELECT *
           FROM   tbl_ContactPersons
           WHERE  ID_NatPerson = @id_person_to
       )
    INSERT INTO tbl_ContactPersons
      (
        ID_JurPerson,
        ID_NatPerson,
        appointment
      )
    SELECT ID_JurPerson,
           @id_person_to,
           appointment
    FROM   tbl_ContactPersons
    WHERE  ID_NatPerson = @id_person_from

DECLARE myCursor CURSOR LOCAL 
FOR
    SELECT table_name,
           column_name,
           id_delete
    FROM   tbl_change_dbl_pers_tables
    ORDER BY
           table_number DESC

OPEN myCursor 
FETCH myCursor
         INTO @table_name, @column_name, @isdelete

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @strout = @table_name 
    PRINT @strout
    
    
    IF @isdelete <> 0
        SET @strsql = 'DELETE ' + @table_name +
            +
            
            ' WHERE ' + @column_name + ' = ' + CAST(@id_person_from AS VARCHAR(10))
    ELSE
        SET @strsql = 'UPDATE ' + @table_name + ' SET ' + @column_name + ' = ' + CAST(@id_person_to AS VARCHAR(10))
            +
            
            ' WHERE ' + @column_name + ' = ' + CAST(@id_person_from AS VARCHAR(10))
    
    
    PRINT @strsql
    
    EXEC (@strsql)
    IF @@ERROR = 2601
       AND @table_name = 'tbl_documents'
    BEGIN
        DELETE 
        FROM   tbl_documents
        WHERE  ID_NatPerson = @id_person_from
        
        EXEC (@strsql)
    END

    FETCH NEXT FROM myCursor
    INTO @table_name, @column_name, @isdelete
END
CLOSE myCursor
DEALLOCATE myCursor

ALTER TABLE loss.tbl_OccurrenceParticipantsCar CHECK CONSTRAINT ALL

SET @result = 1 

IF EXISTS (
       SELECT id_person
       FROM   tbl_Persons
       WHERE  id_person = @id_person_from
   )
BEGIN
    SET @result = 0 
    INSERT INTO tbl_change_dbl_pers
      (
        id_person_From,
        id_person_To,
        operator,
        IsDone
      )
    VALUES
      (
        @id_person_from,
        @id_person_to,
        @login,
        1
      )
END
ELSE
    INSERT INTO tbl_change_dbl_pers
      (
        id_person_From,
        id_person_To,
        operator,
        IsDone
      )
    VALUES
      (
        @id_person_from,
        @id_person_to,
        @login,
        0
      )


SELECT @result
  RETURN @result
