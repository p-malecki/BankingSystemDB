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

IF OBJECT_ID('CardDetails', 'V') IS NOT NULL
DROP VIEW CardDetails
GO
CREATE VIEW CardDetails AS(
SELECT DISTINCT CardID,
    COUNT(Amount) OVER(PARTITION BY Card) 'Operations',
    IsNull(SUM(Amount) OVER(PARTITION BY Card),0) 'Value'
    FROM Cards
    LEFT JOIN(
        SELECT Card, Amount, [Date]
        FROM Withdraws
        UNION ALL
        SELECT Card, Amount, [Date]
        FROM Deposits
        UNION ALL
        SELECT UsedCard, Amount, [Date]
        FROM Transactions
    ) CardOperations ON CardOperations.Card = Cards.CardID
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

IF OBJECT_ID('NumberOfOperationsByAccountsAndCategories', 'V') IS NOT NULL
DROP VIEW NumberOfOperationsByAccountsAndCategories 
GO
CREATE VIEW NumberOfOperationsByAccountsAndCategories AS
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