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
    FROM (
        SELECT Date, -Amount 'Amount', 'Withdraw' 'Operation' 
        FROM Withdraws W
        JOIN Cards C ON C.CardID = W.Card
        JOIN Accounts A ON A.AccountID = C.Account
        WHERE A.AccountID = @account

        UNION ALL

        SELECT Date, Amount, 'Deposit' 'Operation'
        FROM Deposits D
        JOIN Cards C ON C.CardID = D.Card
        JOIN Accounts A ON A.AccountID = C.Account
        WHERE A.AccountID = @account

        UNION ALL

        SELECT Date, -Amount 'Amount', 'Made transaction' 'Operation'
        FROM Transactions T
        JOIN Cards C ON C.CardID = T.UsedCard
        JOIN Accounts A ON A.AccountID = C.Account
        WHERE A.AccountID = @account

        UNION ALL

        SELECT Date, Amount, 'Recived transaction' 'Operation'
        FROM Transactions T
        JOIN Accounts A ON A.AccountID = T.Receiver
        WHERE A.AccountID = @account

        UNION ALL

        SELECT Date, -Amount 'Amount', 'Made transfer' 'Operation' 
        FROM Transfers T
        JOIN Accounts A ON A.AccountID = T.Sender
        WHERE A.AccountID = @account

        UNION ALL

        SELECT Date, Amount, 'Recived transfer' 'Operation' 
        FROM Transfers T
        JOIN Accounts A ON A.AccountID = T.Receiver
        WHERE A.AccountID = @account

        UNION ALL

        SELECT Date, -Amount 'Amount', 'Made phone transfer' 'Operation'
        FROM PhoneTransfers PT
        JOIN Accounts A ON A.AccountID = PT.Sender
        WHERE A.AccountID = @account

        UNION ALL

        SELECT Date, Amount, 'Recived phone transfer' 'Operation'
        FROM PhoneTransfers PT
        JOIN Clients C ON C.PhoneNumber = PT.PhoneReceiver
        JOIN Preferences P ON P.ClientID = C.ClientID
        WHERE P.MainAccount = @account
        ) SUB
)
