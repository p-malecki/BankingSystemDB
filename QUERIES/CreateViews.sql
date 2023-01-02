IF OBJECT_ID('SavingAccountsToUpdate', 'V') IS NOT NULL
DROP VIEW SavingAccountsToUpdate 
GO
CREATE VIEW SavingAccountsToUpdate AS(
    SELECT *
    FROM(
        SELECT SAD.*, A.CurrentBalance,
        CASE
            WHEN InterestRate = 'half year' THEN IIF(MONTH(A.StartDate) % 6 IN (MONTH(GETDATE()), 0), 0, 1)
            WHEN InterestRate = 'quarter' THEN IIF(MONTH(A.StartDate) % 3 IN (MONTH(GETDATE()), 0), 0, 1)
            WHEN InterestRate = 'yearly' THEN IIF(MONTH(A.StartDate) = MONTH(GETDATE()), 0, 1)
            ELSE 0
        END 'mod'
        FROM SavingAccountDetails SAD
        JOIN Accounts A ON A.AccountID = SAD.AccountID
        WHERE A.EndDate IS NULL
    ) SUB
    WHERE mod = 0
)
GO

IF OBJECT_ID('AllOperations', 'V') IS NOT NULL
DROP VIEW AllOperations 
GO
CREATE VIEW AllOperations AS(
    SELECT AccountID, Date, -Amount 'Amount', 'Withdraw' 'Operation' 
    FROM Withdraws W
    JOIN Cards C ON C.CardID = W.Card
    JOIN Accounts A ON A.AccountID = C.Account

    UNION ALL

    SELECT AccountID, Date, Amount, 'Deposit' 'Operation'
    FROM Deposits D
    JOIN Cards C ON C.CardID = D.Card
    JOIN Accounts A ON A.AccountID = C.Account

    UNION ALL

    SELECT AccountID, Date, -Amount 'Amount', 'Made transaction' 'Operation'
    FROM Transactions T
    JOIN Cards C ON C.CardID = T.UsedCard
    JOIN Accounts A ON A.AccountID = C.Account

    UNION ALL

    SELECT AccountID, Date, Amount, 'Recived transaction' 'Operation'
    FROM Transactions T
    JOIN Accounts A ON A.AccountID = T.Receiver

    UNION ALL

    SELECT AccountID, Date, -Amount 'Amount', 'Made transfer' 'Operation' 
    FROM Transfers T
    JOIN Accounts A ON A.AccountID = T.Sender

    UNION ALL

    SELECT AccountID, Date, Amount, 'Recived transfer' 'Operation' 
    FROM Transfers T
    JOIN Accounts A ON A.AccountID = T.Receiver

    UNION ALL

    SELECT AccountID, Date, -Amount 'Amount', 'Made phone transfer' 'Operation'
    FROM PhoneTransfers PT
    JOIN Accounts A ON A.AccountID = PT.Sender

    UNION ALL

    SELECT MainAccount, Date, Amount, 'Recived phone transfer' 'Operation'
    FROM PhoneTransfers PT
    JOIN Clients C ON C.PhoneNumber = PT.PhoneReceiver
    JOIN Preferences P ON P.ClientID = C.ClientID
)
GO

IF OBJECT_ID('AccountHistory', 'IF') IS NOT NULL
DROP FUNCTION AccountHistory 
GO
CREATE FUNCTION AccountHistory(
    @account NVARCHAR(100)
)
RETURNS TABLE
AS
RETURN(
    SELECT ROW_NUMBER() OVER(ORDER BY Date) 'Id',*
    FROM AllOperations
    WHERE AccountID = @account
)
GO

IF OBJECT_ID('AccountOperationsByMonth', 'IF') IS NOT NULL
DROP FUNCTION AccountOperationsByMonth 
GO
CREATE FUNCTION AccountOperationsByMonth(
    @account NVARCHAR(100)
)
RETURNS TABLE
AS
RETURN(
    SELECT MONTH([Date]) 'Month',
    YEAR([Date]) 'Year',
    COUNT(*) 'Operations'
    FROM AccountHistory(@account)
    GROUP BY MONTH([Date]), YEAR([Date])
)
GO

IF OBJECT_ID('ClientOperationsByMonth', 'IF') IS NOT NULL
DROP FUNCTION ClientOperationsByMonth 
GO
CREATE FUNCTION ClientOperationsByMonth(
    @client INT
)
RETURNS TABLE
AS
RETURN(
    SELECT MONTH([Date]) 'Month', YEAR([Date]) 'Year',
    COUNT(*) 'Operations'
    FROM Accounts A
    JOIN AllOperations AO ON AO.AccountID = A.AccountID
    WHERE ClientID = @client
    GROUP BY MONTH([Date]), YEAR([Date])
)
GO

IF OBJECT_ID('ATMOperationsByMonth', 'IF') IS NOT NULL
DROP FUNCTION ATMOperationsByMonth 
GO
CREATE FUNCTION ATMOperationsByMonth(
    @atm INT
)
RETURNS TABLE
AS
RETURN(
    SELECT MONTH([Date]) 'Month', YEAR([Date]) 'Year',
    COUNT(*) 'Operations'
    FROM(
        SELECT *
        FROM Withdraws

        UNION ALL

        SELECT *
        FROM Deposits
    ) Operations 
    WHERE ATMID = @atm
    GROUP BY MONTH([Date]), YEAR([Date])
)
GO

IF OBJECT_ID('NumberOfOperationsByCard', 'V') IS NOT NULL
DROP VIEW NumberOfOperationsByCard 
GO
CREATE VIEW NumberOfOperationsByCard AS(
    SELECT Card,
        COUNT(*) 'Operations'
    FROM(
        SELECT Card, Amount, [Date]
        FROM Withdraws

        UNION ALL

        SELECT Card, Amount, [Date]
        FROM Withdraws

        UNION ALL

        SELECT UsedCard, Amount, [Date]
        FROM Transactions
    ) CardOperations
    GROUP BY Card
)
GO

IF OBJECT_ID('ClientOperationsByCard', 'IF') IS NOT NULL
DROP FUNCTION ClientOperationsByCard 
GO
CREATE FUNCTION ClientOperationsByCard(
    @client INT
)
RETURNS TABLE
AS
RETURN(
    SELECT A.ClientID, C.CardID, N.Operations
    FROM Accounts A
    JOIN Cards C ON C.Account = A.AccountID
    JOIN NumberOfOperationsByCard N ON N.Card = C.CardID
)
GO

IF OBJECT_ID('GetPassword', 'FN') IS NOT NULL
DROP FUNCTION GetPassword
GO
CREATE FUNCTION GetPassword(
    @account NVARCHAR(100)
)
RETURNS NVARCHAR(100)
AS
BEGIN
RETURN(
    SELECT [Password]
    FROM Accounts
    WHERE AccountID = @account
)
END
GO

IF OBJECT_ID('IfAccountExists', 'FN') IS NOT NULL
DROP FUNCTION IfAccountExists
GO
CREATE FUNCTION IfAccountExists(
    @account NVARCHAR(100)
)
RETURNS BIT
AS
BEGIN
RETURN(
    SELECT IIF('AD0357942949XKSMVLBOOIBA' IN (
        SELECT AccountID
        FROM Accounts), 1, 0)
)
END
GO