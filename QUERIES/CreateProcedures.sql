DROP PROCEDURE addNewClient
GO
CREATE PROCEDURE addNewClient
@name NVARCHAR(100),
@dateOfBirth DATE,
@city NVARCHAR(100),
@country NVARCHAR(100),
@phoneNumber NVARCHAR(100),
@allowPhoneTransfers BIT
AS
BEGIN
    INSERT INTO Clients VALUES
    (@name, @dateOfBirth, @city, @country, @phoneNumber);
    
    INSERT INTO Preferences VALUES
    (@@IDENTITY , NULL, @allowPhoneTransfers)
END
GO

DROP PROCEDURE IF EXISTS addNewAccount
GO
CREATE PROCEDURE addNewAccount
@accountID NVARCHAR(100),
@clientID INT,
@name NVARCHAR(100),
@accountType INT,
@password NVARCHAR(100)
AS
IF LEN(@password) < 20
	BEGIN
		RAISERROR('Password not strong enough',17,1);
	END
ELSE
	BEGIN
		INSERT INTO Accounts VALUES
		(@accountID, @clientID, @name, @accountType, 0, CAST(GETDATE() AS Date), NULL, @password)

		IF (SELECT MainAccount FROM Preferences WHERE ClientID = @clientID) IS NULL
			UPDATE Preferences
			SET MainAccount = @accountID
			WHERE ClientID = @clientID
	END
GO

DROP PROCEDURE IF EXISTS addNewCard
GO
CREATE PROCEDURE addNewCard
@cardID NVARCHAR(100),
@account NVARCHAR(100),
@limit INT,
@pin INT
AS
IF (SELECT EndDate FROM Accounts WHERE AccountID = @account) IS NOT NULL
		RAISERROR('Account has been closed', 17 ,1)
ELSE IF @limit < 0
BEGIN
	RAISERROR('Incorrect limit',17,1);
END
ELSE
BEGIN
    INSERT INTO Cards VALUES
    (@cardID, @account, @limit, @pin);
END
GO

DROP PROCEDURE IF EXISTS addNewTransfer
GO
CREATE PROCEDURE addNewTransfer
@sender NVARCHAR(100),
@receiver NVARCHAR(100),
@amount MONEY,
@title NVARCHAR(100),
@category INT
AS
IF @amount <= 0
BEGIN
	RAISERROR('Incorrect amount',17,1)
END
ELSE IF (SELECT EndDate FROM Accounts WHERE AccountID = @sender) IS NOT NULL
		RAISERROR('Account has been closed', 17 ,1)
ELSE IF ( SELECT CurrentBalance
		FROM Accounts
		WHERE AccountID = @sender ) < @amount
BEGIN
	RAISERROR('Not enough funds',17,1)
END
ELSE IF @sender = @receiver
BEGIN
	RAISERROR('Incorrect operation',17,1)
END
ELSE
BEGIN
    INSERT INTO Transfers VALUES
    (@sender, @receiver, @amount, @title, CAST(GETDATE() AS Date), @category, NULL)
END
GO

DROP PROCEDURE IF EXISTS addNewPhoneTransfer
GO
CREATE PROCEDURE addNewPhoneTransfer
@sender NVARCHAR(100),
@phoneReceiver NVARCHAR(100),
@amount MONEY,
@title NVARCHAR(100),
@category INT
AS
IF @amount <= 0
BEGIN
	RAISERROR('Incorrect amount',17,1)
END
ELSE IF (SELECT EndDate FROM Accounts WHERE AccountID = @sender) IS NOT NULL
		RAISERROR('Account has been closed', 17 ,1)
ELSE IF ( SELECT CurrentBalance
		FROM Accounts
		WHERE AccountID = @sender ) < @amount
BEGIN
	RAISERROR('Not enough funds',17,1)
END
ELSE IF ( SELECT AllowPhoneTransfer
		FROM Preferences P
		JOIN Clients C ON C.ClientID = P.ClientID
		WHERE C.PhoneNumber = @phoneReceiver ) = 0
BEGIN
	RAISERROR('Receiver does not accept phoneTransfers',17,1)
END
ELSE IF ( SELECT MainAccount
		FROM Preferences P
		JOIN Clients C ON C.ClientID = P.ClientID
		WHERE C.PhoneNumber = @phoneReceiver ) = @sender
BEGIN
	RAISERROR('Incorrect operation',17,1)
END
ELSE
BEGIN
	INSERT INTO PhoneTransfers VALUES
	(@sender, @phoneReceiver, @amount, @title, CAST(GETDATE() AS Date), @category)
END
GO

DROP PROCEDURE IF EXISTS makeWithdraw
GO
CREATE PROCEDURE makeWithdraw
@card NVARCHAR(100),
@amount MONEY,
@ATM INT
AS
BEGIN
	IF @amount <= 0
		RAISERROR('Incorrect amount',17,1)
	ELSE IF (SELECT EndDate FROM Accounts JOIN Cards ON Account = AccountID WHERE CardID = @card) IS NOT NULL
		RAISERROR('Account has been closed', 17 ,1)
	ELSE IF NOT EXISTS(SELECT * FROM ATMs WHERE ATMID = @ATM)
		RAISERROR('ATM does not exist',17,1)
	ELSE IF @amount > (SELECT CurrentBalance FROM ATMs WHERE ATMID = @ATM)
		RAISERROR('ATM does not have enough funds',17,1)	
	ELSE IF @amount > (
		SELECT CurrentBalance
		FROM Accounts A
		JOIN Cards C ON C.Account = A.AccountID
		WHERE C.CardID = @card)
		RAISERROR('Not enough funds',17,1)
	ELSE
		INSERT INTO Withdraws VALUES
		(@card, @amount, @ATM, GETDATE())
END
GO

DROP PROCEDURE IF EXISTS makeDeposit
GO
CREATE PROCEDURE makeDeposit
@card NVARCHAR(100),
@amount MONEY,
@ATM INT
AS
BEGIN
	IF @amount <= 0
		RAISERROR('Incorrect amount',17,1)
	ELSE IF (SELECT EndDate FROM Accounts JOIN Cards ON Account = AccountID WHERE CardID = @card) IS NOT NULL
		RAISERROR('Account has been closed', 17 ,1)
	ELSE IF NOT EXISTS(SELECT * FROM ATMs WHERE ATMID = @ATM)
		RAISERROR('ATM does not exist',17,1)	
	ELSE
		INSERT INTO Deposits VALUES
		(@card, @amount, @ATM, GETDATE())
END
GO

DROP PROCEDURE IF EXISTS makeTransaction
GO
CREATE PROCEDURE makeTransaction
@card NVARCHAR(100),
@receiver NVARCHAR(100),
@amount MONEY,
@title NVARCHAR(100),
@category INT
AS
BEGIN
	IF @amount <= 0
		RAISERROR('Incorrect amount', 17 ,1)
	ELSE IF (SELECT EndDate FROM Accounts JOIN Cards ON Account = AccountID WHERE CardID = @card) IS NOT NULL
		RAISERROR('Account has been closed', 17 ,1)
	ELSE IF @amount > (
		SELECT CurrentBalance
		FROM Accounts A
		JOIN Cards C ON C.Account = A.AccountID
		WHERE C.CardID = @card)
		RAISERROR('Not enough funds', 17, 1)
	ELSE IF @receiver = (SELECT Account FROM Cards WHERE CardID = @card)
		RAISERROR('Incorrect operation', 17, 1)
	ELSE
		INSERT INTO Transactions VALUES
		(@card, @receiver, @amount, GETDATE(), @category)
END