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
