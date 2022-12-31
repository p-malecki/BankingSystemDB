DROP PROCEDURE IF EXISTS checkLoans
GO
CREATE PROCEDURE checkLoans
AS
BEGIN
    UPDATE Accounts
    SET CurrentBalance = A.CurrentBalance - L.Amount
    FROM Accounts A
    JOIN Loans L ON L.AccountID = A.AccountID
    WHERE L.EndDate = GETDATE()
END
GO

DROP PROCEDURE IF EXISTS checkSavingAccounts
GO
CREATE PROCEDURE checkSavingAccounts
AS
BEGIN
    DECLARE @month INT = MONTH(GETDATE())
    DECLARE @rowCount INT = (SELECT COUNT(*) FROM SavingAccountsToUpdate)
    DECLARE @temp TABLE(ID INT IDENTITY, Account NVARCHAR(100), Frequency FLOAT, CurrentBalance MONEY)
    DECLARE @id INT = 1

    INSERT INTO @temp (Account, Frequency, CurrentBalance)
    SELECT AccountID, Frequency, CurrentBalance FROM SavingAccountsToUpdate

    DECLARE @account NVARCHAR(100)
    DECLARE @frequency FLOAT
    DECLARE @balance MONEY

    WHILE @rowCount > 0 
    BEGIN
        SELECT @id = ID,
            @account = Account,
            @frequency = Frequency,
            @balance = CurrentBalance
        FROM @temp
        ORDER BY ID DESC OFFSET @rowCount - 1 ROWS FETCH NEXT 1 ROWS ONLY;

        DECLARE @amount MONEY = CAST(@balance * @frequency AS MONEY)
        
       INSERT INTO Transfers VALUES
       ('JAKIES KONTO',@account,@amount,'Saving Account Income',GETDATE(),1,NULL)
       SET @rowCount = @rowCount - 1
    END 
END
GO

USE msdb
GO

IF EXISTS(SELECT * FROM dbo.sysschedules WHERE name = 'Daily')
    EXEC sp_delete_schedule @schedule_name = 'Daily'
GO
EXEC sp_add_schedule
    @schedule_name = N'Daily',  
    @freq_type = 4, --daily  
    @freq_interval = 1,
    @active_start_time = 000000 ; --every midnight
GO

IF EXISTS(SELECT * FROM dbo.sysschedules WHERE name = 'Monthly')
    EXEC sp_delete_schedule @schedule_name = 'Monthly'
GO
EXEC sp_add_schedule
    @schedule_name = N'Monthly',  
    @freq_type = 16, --monthly  
    @freq_interval = 1, --on the 1st day of the month
    @freq_recurrence_factor = 1,
    @active_start_time = 000000 ; --every midnight
GO

IF EXISTS(SELECT * FROM dbo.sysjobs WHERE name = 'checkLoans')
    EXEC sp_delete_job @job_name = 'checkLoans'
GO
EXEC sp_add_job
    @job_name = 'checkLoans'
GO

EXEC sp_add_jobstep  
    @job_name = N'checkLoans',  
    @step_name = N'CheckLoans',  
    @subsystem = N'TSQL',  
    @command = N'EXEC checkLoans',   
    @retry_attempts = 5,  
    @retry_interval = 5;  
GO  

IF EXISTS(SELECT * FROM dbo.sysjobs WHERE name = 'checkSavingAcoounts')
    EXEC sp_delete_job @job_name = 'checkSavingAcoounts'
GO
EXEC sp_add_job
    @job_name = 'checkSavingAcoounts'
GO

EXEC sp_add_jobstep  
    @job_name = N'checkSavingAcoounts',  
    @step_name = N'CheckSavingAcoounts',  
    @subsystem = N'TSQL',  
    @command = N'EXEC checkSavingAccounts',   
    @retry_attempts = 5,  
    @retry_interval = 5;  
GO  
