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

IF EXISTS(SELECT * FROM dbo.sysjobs WHERE name = 'checkLoans')
    EXEC sp_delete_job @job_name = 'checkLoans'
GO
EXEC sp_add_job
    @job_name = 'checkLoans'
GO

DROP PROCEDURE IF EXISTS checkLoans
GO
EXEC sp_add_jobstep  
    @job_name = N'checkLoans',  
    @step_name = N'CheckLoans',  
    @subsystem = N'TSQL',  
    @command = N'EXEC checkLoans',   
    @retry_attempts = 5,  
    @retry_interval = 5;  
GO  
