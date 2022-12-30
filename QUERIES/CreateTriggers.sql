CREATE TRIGGER newWithdraw
ON dbo.Withdraws
AFTER INSERT
AS
BEGIN
	UPDATE Accounts
	SET CurrentBalance = A.CurrentBalance - i.Amount
    FROM Accounts A
    JOIN Cards C ON C.Account = A.AccountID
    JOIN inserted i ON i.Card = C.CardID

	UPDATE ATMs
	SET CurrentBalance = A.CurrentBalance - i.Amount
    FROM ATMs A
    JOIN inserted i ON i.ATMID = A.ATMID
END
GO

CREATE TRIGGER newDeposit
ON dbo.Deposits
AFTER INSERT
AS
BEGIN
    UPDATE Accounts
	SET CurrentBalance = A.CurrentBalance + i.Amount
    FROM Accounts A
    JOIN Cards C ON C.Account = A.AccountID
    JOIN inserted i ON i.Card = C.CardID

	UPDATE ATMs
	SET CurrentBalance = A.CurrentBalance + i.Amount
    FROM ATMs A
    JOIN inserted i ON i.ATMID = A.ATMID
END
GO

CREATE TRIGGER newTransaction
ON dbo.Transactions
AFTER INSERT
AS
BEGIN
	UPDATE Accounts
	SET CurrentBalance = A.CurrentBalance - i.Amount
	FROM Accounts A
	JOIN Cards C ON C.Account = A.AccountID
	JOIN inserted i ON i.UsedCard = C.CardID

	IF (SELECT TOP 1 Receiver FROM inserted ORDER BY TransactionID) IN (SELECT AccountID FROM Accounts)
    BEGIN
        UPDATE Accounts
        SET CurrentBalance = A.CurrentBalance + i.Amount
        FROM Accounts A
        JOIN inserted i ON i.Receiver = A.AccountID
    END
END
GO

CREATE TRIGGER newTransfer
ON dbo.Transfers
AFTER INSERT
AS
BEGIN
	UPDATE Accounts
	SET CurrentBalance = A.CurrentBalance - i.Amount
	FROM Accounts A
	JOIN inserted i ON i.Sender = A.AccountID

	IF (SELECT TOP 1 Receiver FROM inserted ORDER BY TransferID) IN (SELECT AccountID FROM Accounts)
    BEGIN
        UPDATE Accounts
        SET CurrentBalance = A.CurrentBalance + i.Amount
        FROM Accounts A
        JOIN inserted i ON i.Receiver = A.AccountID
    END
END
GO

CREATE TRIGGER newPhoneTransfer
ON dbo.PhoneTransfers
AFTER INSERT
AS
BEGIN
	UPDATE Accounts
	SET CurrentBalance = A.CurrentBalance - i.Amount
	FROM Accounts A
	JOIN inserted i ON i.Sender = A.AccountID

	IF (SELECT TOP 1 PhoneReceiver FROM inserted ORDER BY TransferID) IN (SELECT PhoneNumber FROM Clients)
    BEGIN
        UPDATE Accounts
        SET CurrentBalance = A.CurrentBalance + i.Amount
        FROM Accounts A
		JOIN Preferences P ON P.MainAccount = A.AccountID
		JOIN Clients C ON C.ClientID = P.ClientID
        JOIN inserted i ON i.PhoneReceiver = C.PhoneNumber
    END
END
GO