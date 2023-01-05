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

IF OBJECT_ID('StandingOrdersToSend', 'V') IS NOT NULL
DROP VIEW StandingOrdersToSend 
GO
CREATE VIEW StandingOrdersToSend AS(
    SELECT *
    FROM StandingOrders
    WHERE StartDate <= CAST(GETDATE() AS Date) AND CAST(GETDATE() AS Date) <= EndDate
	AND DAY(StartDate) = DAY(GETDATE())
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
    @clientID INT
)
RETURNS TABLE
AS
RETURN(
    SELECT MONTH([Date]) 'Month', YEAR([Date]) 'Year',
    COUNT(*) 'Operations'
    FROM Accounts A
    JOIN AllOperations AO ON AO.AccountID = A.AccountID
    WHERE ClientID = @clientID
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
	@clientID INT
)
RETURNS TABLE
AS
RETURN(
    SELECT A.ClientID, C.CardID, N.Operations
    FROM Accounts A
    JOIN Cards C ON C.Account = A.AccountID
    JOIN NumberOfOperationsByCard N ON N.Card = C.CardID
	WHERE A.ClientID = @clientID
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
    SELECT IIF(@account IN (
        SELECT AccountID
        FROM Accounts), 1, 0)
)
END
GO

IF OBJECT_ID('CardDetails', 'V') IS NOT NULL
DROP VIEW CardDetails
GO
CREATE VIEW CardDetails AS(
SELECT DISTINCT Card,
    COUNT(Amount) OVER(PARTITION BY Card) 'Operations',
    SUM(Amount) OVER(PARTITION BY Card) 'Value'
    FROM(
        SELECT Card, Amount, [Date]
        FROM Withdraws
        UNION ALL
        SELECT Card, Amount, [Date]
        FROM Deposits
        UNION ALL
        SELECT UsedCard, Amount, [Date]
        FROM Transactions
    ) CardOperations
)


IF OBJECT_ID('ATM_MalfunctionsHistory', 'IF') IS NOT NULL
DROP FUNCTION ATM_MalfunctionsHistory 
GO
CREATE FUNCTION ATM_MalfunctionsHistory(@atmID INT)
RETURNS TABLE
AS
RETURN (
	SELECT *
	FROM ATMsMalfunctions
	WHERE ATMID = @atmID
)
GO

IF OBJECT_ID('NumberOfOperationsByAccount', 'V') IS NOT NULL
DROP VIEW NumberOfOperationsByAccount 
GO
CREATE VIEW NumberOfOperationsByAccount AS
    SELECT Account, COUNT(*) 'Operations'
    FROM(
        SELECT Amount, [Date], Sender AS [Account]
        FROM Transfers
        UNION ALL
		SELECT Amount, [Date], Receiver AS [Account]
        FROM Transfers
        UNION ALL
        SELECT Amount, [Date], (SELECT Account FROM Cards WHERE CardID = T.UsedCard) AS [Account]
        FROM Transactions T
		UNION ALL
        SELECT Amount, [Date], Receiver AS [Account]
        FROM Transactions T
        UNION ALL
        SELECT Amount, [Date], Sender AS [Account]
        FROM PhoneTransfers PT
		UNION ALL
        SELECT Amount, [Date], (SELECT MainAccount FROM Preferences P
								JOIN Clients C ON C.ClientID = P.ClientID
								WHERE C.PhoneNumber = PT.PhoneReceiver) AS [Account]
        FROM PhoneTransfers PT
    ) AccountOperations
    WHERE Account IS NOT NULL
	GROUP BY Account
GO

IF OBJECT_ID('NumberOfOperationsByClient', 'V') IS NOT NULL
DROP VIEW NumberOfOperationsByClient 
GO
CREATE VIEW NumberOfOperationsByClient AS
    SELECT A.ClientID, SUM(N.Operations) AS 'Operations'
    FROM NumberOfOperationsByAccount N
	JOIN Accounts A ON A.AccountID = N.Account
	GROUP BY A.ClientID
GO

IF OBJECT_ID('NumberOfOperationsByAccountsAndCatergories', 'V') IS NOT NULL
DROP VIEW NumberOfOperationsByAccountsAndCatergories 
GO
CREATE VIEW NumberOfOperationsByAccountsAndCatergories AS
    SELECT Account, Category, COUNT(*) 'Operations'
    FROM(
        SELECT Category, Amount, [Date], Sender AS [Account]
        FROM Transfers
        UNION ALL
		SELECT Category, Amount, [Date], Receiver AS [Account]
        FROM Transfers
        UNION ALL
        SELECT Category, Amount, [Date], (SELECT Account FROM Cards WHERE CardID = T.UsedCard) AS [Account]
        FROM Transactions T
		UNION ALL
        SELECT Category, Amount, [Date], Receiver AS [Account]
        FROM Transactions T
        UNION ALL
        SELECT Category, Amount, [Date], Sender AS [Account]
        FROM PhoneTransfers PT
		UNION ALL
        SELECT Category, Amount, [Date], (SELECT MainAccount FROM Preferences P
										  JOIN Clients C ON C.ClientID = P.ClientID
										  WHERE C.PhoneNumber = PT.PhoneReceiver) AS [Account]
        FROM PhoneTransfers PT
    ) AccountOperations
    WHERE Account IS NOT NULL
	GROUP BY Category, Account
GO

IF OBJECT_ID('ClientOperationsByCategories', 'IF') IS NOT NULL
DROP FUNCTION ClientOperationsByCategories
GO
CREATE FUNCTION ClientOperationsByCategories()
RETURNS TABLE
AS
RETURN(
    SELECT A.ClientID, N.Category, SUM(N.Operations) AS 'Operations'
    FROM NumberOfOperationsByAccountsAndCatergories N
	JOIN Accounts A ON A.AccountID = N.Account
	GROUP BY A.ClientID, N.Category
)
GO

IF OBJECT_ID('NumberOfTransfersByClient', 'V') IS NOT NULL
DROP VIEW NumberOfTransfersByClient 
GO
CREATE VIEW NumberOfTransfersByClient AS
    SELECT A.ClientID, COUNT(T.[Account]) AS 'Operations'
    FROM (SELECT Sender AS [Account]
          FROM Transfers
          UNION ALL
		  SELECT Receiver AS [Account]
          FROM Transfers) T
	JOIN Accounts A ON A.AccountID = T.Account
	GROUP BY A.ClientID
GO

IF OBJECT_ID('NumberOfTransfersByClient', 'V') IS NOT NULL
DROP VIEW NumberOfTransfersByClient 
GO
CREATE VIEW NumberOfTransfersByClient AS
    SELECT A.ClientID, COUNT(T.[Account]) AS 'Operations'
    FROM (SELECT Sender AS [Account]
          FROM Transfers
          UNION ALL
		  SELECT Receiver AS [Account]
          FROM Transfers) T
	JOIN Accounts A ON A.AccountID = T.Account
	GROUP BY A.ClientID
GO

IF OBJECT_ID('ClientTransfersNumber', 'IF') IS NOT NULL
DROP FUNCTION ClientTransfersNumber 
GO
CREATE FUNCTION ClientTransfersNumber(@clientID INT)
RETURNS TABLE
AS
RETURN(
    SELECT ClientID, N.Operations
    FROM NumberOfTransfersByClient N
	WHERE ClientID = @clientID
)
GO

IF OBJECT_ID('NumberOfPhoneTransfersByClient', 'V') IS NOT NULL
DROP VIEW NumberOfPhoneTransfersByClient 
GO
CREATE VIEW NumberOfPhoneTransfersByClient AS
    SELECT ClientID, COUNT(PT.ClientID) AS 'Operations'
    FROM (SELECT ClientID
          FROM PhoneTransfers tmpPT
		  JOIN Accounts A ON A.AccountID = tmpPT.Sender
          UNION ALL
		  SELECT ClientID
		  FROM PhoneTransfers tmpPT
		  JOIN Clients C ON C.PhoneNumber = tmpPT.PhoneReceiver
	) PT
	GROUP BY ClientID
GO

IF OBJECT_ID('ClientPhoneTransfersNumber', 'IF') IS NOT NULL
DROP FUNCTION ClientPhoneTransfersNumber 
GO
CREATE FUNCTION ClientPhoneTransfersNumber(@clientID INT)
RETURNS TABLE
AS
RETURN(
    SELECT ClientID, N.Operations
    FROM NumberOfPhoneTransfersByClient N
	WHERE ClientID = @clientID
)
GO

IF OBJECT_ID('ClientRankingByOperationType', 'IF') IS NOT NULL
DROP FUNCTION ClientRankingByOperationType
GO
CREATE FUNCTION ClientRankingByOperationType(@clientID INT)
RETURNS TABLE
AS
RETURN(
    SELECT 'Transfers: ' AS 'Type', Operations
	FROM ClientTransfersNumber(@clientID)
	UNION ALL
	SELECT 'Card Operations: ' AS 'Type', SUM(Operations)
	FROM ClientOperationsByCard(@clientID)
	UNION ALL
	SELECT 'Transactions: ' AS 'Type', Operations
	FROM ClientPhoneTransfersNumber(@clientID)
)
GO

IF OBJECT_ID('OnOwnAccountsTransfers', 'IF') IS NOT NULL
DROP FUNCTION OnOwnAccountsTransfers
GO
CREATE FUNCTION OnOwnAccountsTransfers(@clientID INT)
RETURNS TABLE
AS
RETURN(
    SELECT *
	FROM Transfers
	WHERE Sender IN (SELECT AccountID FROM Accounts WHERE ClientID = @clientID)
	AND Receiver IN (SELECT AccountID FROM Accounts WHERE ClientID = @clientID)
)
GO
-- test for client 4

IF OBJECT_ID('DepartmentATMsBalance', 'IF') IS NOT NULL
DROP FUNCTION De
GO
CREATE FUNCTION DepartmentATMsBalance(@departamentID INT)
RETURNS TABLE
AS
RETURN(
    SELECT SUM(CurrentBalance) as balancesSUM
	FROM ATMs
	WHERE SupervisorDepartment = @departamentID
	GROUP BY SupervisorDepartment
)
GO

