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
END



DROP PROCEDURE IF EXISTS addNewCard
GO
CREATE PROCEDURE addNewCard
@cardID NVARCHAR(100),
@account NVARCHAR(100),
@limit INT,
@pin INT
AS
IF @limit < 0
BEGIN
	RAISERROR('Incorrect limit',17,1);
END
ELSE
BEGIN
    INSERT INTO Cards VALUES
    (@cardID, @account, @limit, @pin);
END



DROP PROCEDURE IF EXISTS addNewTransfer
GO
CREATE PROCEDURE addNewTransfer
@sender NVARCHAR(100),
@receiver NVARCHAR(100),
@amount INT,
@title NVARCHAR(100),
@category INT
AS
IF @amount <= 0
BEGIN
	RAISERROR('Incorrect amount',17,1)
END
ELSE IF ( SELECT TOP 1 CurrentBalance
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



DROP PROCEDURE IF EXISTS addNewPhoneTransfer
GO
CREATE PROCEDURE addNewPhoneTransfer
@sender NVARCHAR(100),
@phoneReceiver NVARCHAR(100),
@amount INT,
@title NVARCHAR(100),
@category INT
AS
IF @amount <= 0
BEGIN
	RAISERROR('Incorrect amount',17,1)
END
ELSE IF ( SELECT TOP 1 CurrentBalance
		FROM Accounts
		WHERE AccountID = @sender ) < @amount
BEGIN
	RAISERROR('Not enough funds',17,1)
END
ELSE IF ( SELECT TOP 1 AllowPhoneTransfer
		FROM Preferences P
		JOIN Clients C ON C.ClientID = P.ClientID
		WHERE C.PhoneNumber = @phoneReceiver ) = 0
BEGIN
	RAISERROR('Receiver does not accept phoneTransfers',17,1)
END
ELSE IF ( SELECT TOP 1 MainAccount
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
