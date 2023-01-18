USE DBproject
DROP PROCEDURE IF EXISTS createBackup
GO
CREATE PROCEDURE createBackup
AS
BEGIN 
    DECLARE @path NVARCHAR(100) = 'C:\Users\Konrad\Desktop\BAZA BACKUP\'
    DECLARE @filename NVARCHAR(100) = 'backup' + CONVERT(NVARCHAR, GETDATE(), 5) + '.bak'
    DECLARE @final NVARCHAR(100) = @path + @filename

    BACKUP DATABASE DBproject
    TO DISK = @final
END
GO

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
	--DECLARE @month INT = MONTH(GETDATE())
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
        ORDER BY ID DESC OFFSET @rowCount - 1 ROWS FETCH NEXT 1 ROWS ONLY

        DECLARE @amount MONEY = CAST(@balance * @frequency AS MONEY)
        
       INSERT INTO Transfers VALUES
       ('BANK',@account,@amount,'Saving Account Income',GETDATE(),1,NULL)
       SET @rowCount = @rowCount - 1
    END 
END
GO

DROP PROCEDURE IF EXISTS checkStandingOrders
GO
CREATE PROCEDURE checkStandingOrders
AS
BEGIN
    DECLARE @rowCount INT = (SELECT COUNT(*) FROM StandingOrdersToSend)
    DECLARE @temp TABLE(ID INT IDENTITY, Sender NVARCHAR(100), Receiver NVARCHAR(100), Amount MONEY, Title NVARCHAR(100))
    DECLARE @id INT = 1

    INSERT INTO @temp (Sender, Receiver, Amount, Title)
    SELECT SOS.Sender, SOS.Receiver, SOS.Amount, SOS.Title FROM StandingOrdersToSend SOS

    DECLARE @tmp_sender NVARCHAR(100)
    DECLARE @tmp_receiver NVARCHAR(100)
    DECLARE @tmp_amount MONEY
	DECLARE @tmp_title NVARCHAR(100)

    WHILE @rowCount > 0 
    BEGIN
        SELECT @id = ID,
            @tmp_sender = Sender,
            @tmp_receiver = Receiver,
            @tmp_amount = Amount,
			@tmp_title = Title
        FROM @temp
        ORDER BY ID DESC OFFSET @rowCount - 1 ROWS FETCH NEXT 1 ROWS ONLY

       EXEC [dbo].[addNewTransfer] @sender = @tmp_sender, @receiver = @tmp_receiver, @amount = @tmp_amount, @title = @tmp_title, @category=11

       SET @rowCount = @rowCount - 1
    END 
END
GO

USE msdb
GO

-- DELETING 
IF EXISTS(SELECT * FROM dbo.sysjobs WHERE name = 'checkSavingAcoounts')
    EXEC sp_delete_job @job_name = 'checkSavingAcoounts'
GO
IF EXISTS(SELECT * FROM dbo.sysjobs WHERE name = 'checkLoans')
    EXEC sp_delete_job @job_name = 'checkLoans'
GO
IF EXISTS(SELECT * FROM dbo.sysjobs WHERE name = 'checkStandingOrders')
    EXEC sp_delete_job @job_name = 'checkStandingOrders'
GO
IF EXISTS(SELECT * FROM dbo.sysjobs WHERE name = 'monthlyBackup')
    EXEC sp_delete_job @job_name = 'monthlyBackup'
GO

IF EXISTS(SELECT * FROM dbo.sysschedules WHERE name = 'Daily')
    EXEC sp_delete_schedule @schedule_name = 'Daily'
GO
IF EXISTS(SELECT * FROM dbo.sysschedules WHERE name = 'Monthly')
    EXEC sp_delete_schedule @schedule_name = 'Monthly'
GO

-- CREATING SCHEDULES
EXEC sp_add_schedule
    @schedule_name = N'Daily',  
    @freq_type = 4, --daily  
    @freq_interval = 1,
    @active_start_time = 000000 ; --every midnight
GO

EXEC sp_add_schedule
    @schedule_name = N'Monthly',  
    @freq_type = 16, --monthly  
    @freq_interval = 1, --on the 1st day of the month
    @freq_recurrence_factor = 1,
    @active_start_time = 000000 ; --every midnight
GO

-- LOANS CHECK
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
EXEC sp_attach_schedule
    @job_name = N'checkLoans',
    @schedule_name = N'Daily'
GO

-- SAVING ACCOUNTS CHECK
EXEC sp_add_job
    @job_name = N'checkSavingAcoounts'
GO
EXEC sp_add_jobstep  
    @job_name = N'checkSavingAcoounts',  
    @step_name = N'CheckSavingAcoounts',  
    @subsystem = N'TSQL',  
    @command = N'EXEC checkSavingAccounts',   
    @retry_attempts = 5,  
    @retry_interval = 5;  
GO  
EXEC sp_attach_schedule
    @job_name = N'checkSavingAcoounts',
    @schedule_name = N'Monthly'
GO  

-- STANDING ORDERS CHECK
EXEC sp_add_job
    @job_name = N'checkStandingOrders'
GO
EXEC sp_add_jobstep  
    @job_name = N'checkStandingOrders',  
    @step_name = N'CheckStandingOrders',  
    @subsystem = N'TSQL',  
    @command = N'EXEC checkStandingOrders',   
    @retry_attempts = 5,  
    @retry_interval = 5;  
GO
GO  
EXEC sp_attach_schedule
    @job_name = N'checkStandingOrders',
    @schedule_name = N'Daily'
GO
-- DATABASE BACKUP
EXEC sp_add_job
    @job_name = N'monthlyBackup'
GO
EXEC sp_add_jobstep  
    @job_name = N'monthlyBackup',  
    @step_name = N'CreateMonthlyBackupOfDB',  
    @subsystem = N'TSQL',  
    @command = N'EXEC createBackup',   
    @retry_attempts = 5,  
    @retry_interval = 5;  
GO
GO  
EXEC sp_attach_schedule
    @job_name = N'monthlyBackup',
    @schedule_name = N'Monthly'
GO