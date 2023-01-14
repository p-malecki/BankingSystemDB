IF OBJECT_ID('ClientOperationsByMonth', 'IF') IS NOT NULL
DROP FUNCTION ClientOperationsByMonth 
GO
CREATE FUNCTION ClientOperationsByMonth(@clientID INT)
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

IF OBJECT_ID('ClientOperationsByCard', 'IF') IS NOT NULL
DROP FUNCTION ClientOperationsByCard 
GO
CREATE FUNCTION ClientOperationsByCard(@clientID INT)
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

IF OBJECT_ID('ClientOperationsByOperationType', 'IF') IS NOT NULL
DROP FUNCTION ClientOperationsByOperationType
GO
CREATE FUNCTION ClientOperationsByOperationType(@clientID INT)
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

IF OBJECT_ID('NumberOfOperationsByCategories', 'IF') IS NOT NULL
DROP FUNCTION NumberOfOperationsByCategories
GO
CREATE FUNCTION NumberOfOperationsByCategories()
RETURNS TABLE
AS
RETURN(
    SELECT A.ClientID, N.Category, SUM(N.Operations) AS 'Operations'
    FROM NumberOfOperationsByAccountsAndCategories N
	JOIN Accounts A ON A.AccountID = N.Account
	GROUP BY A.ClientID, N.Category
)
GO

IF OBJECT_ID('ClientOperationsByCategories', 'IF') IS NOT NULL
DROP FUNCTION ClientOperationsByCategories 
GO
CREATE FUNCTION ClientOperationsByCategories(@clientID INT)
RETURNS TABLE
AS
RETURN(
    SELECT N.Category, N.Operations
    FROM NumberOfOperationsByCategories() N
	WHERE ClientID = @clientID
)
GO


IF OBJECT_ID('AccountHistory', 'IF') IS NOT NULL
DROP FUNCTION AccountHistory 
GO
CREATE FUNCTION AccountHistory(@account NVARCHAR(100))
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
CREATE FUNCTION AccountOperationsByMonth(@account NVARCHAR(100))
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

IF OBJECT_ID('GetPassword', 'FN') IS NOT NULL
DROP FUNCTION GetPassword
GO
CREATE FUNCTION GetPassword(@account NVARCHAR(100))
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

IF OBJECT_ID('GetPIN', 'FN') IS NOT NULL
DROP FUNCTION GetPIN
GO
CREATE FUNCTION GetPIN(@cardID NVARCHAR(100))
RETURNS NVARCHAR(100)
AS
BEGIN
RETURN(
    SELECT PIN
    FROM Cards
    WHERE CardID = @cardID
)
END
GO

IF OBJECT_ID('IfAccountExists', 'FN') IS NOT NULL
DROP FUNCTION IfAccountExists
GO
CREATE FUNCTION IfAccountExists(@account NVARCHAR(100))
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

IF OBJECT_ID('DepartmentATMsBalance', 'IF') IS NOT NULL
DROP FUNCTION DepartmentATMsBalance
GO
CREATE FUNCTION DepartmentATMsBalance(@departmentID INT)
RETURNS TABLE
AS
RETURN(
    SELECT SUM(CurrentBalance) as balancesSUM
	FROM ATMs
	WHERE SupervisorDepartment = @departmentID
	GROUP BY SupervisorDepartment
)
GO

IF OBJECT_ID('ATMOperationsByMonth', 'IF') IS NOT NULL
DROP FUNCTION ATMOperationsByMonth 
GO
CREATE FUNCTION ATMOperationsByMonth(@atm INT)
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