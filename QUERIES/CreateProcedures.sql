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
	IF @dateOfBirth > GETDATE()
		RAISERROR('Date of Birth can not be in the future', 17, 1)
	ELSE IF @dateOfBirth >  CAST(DATEADD(YEAR, -16, GETDATE()) AS DATE)
		RAISERROR('Client must be older than the age of 16 ', 17, 1)
	ELSE
	BEGIN
		INSERT INTO Clients VALUES
		(@name, @dateOfBirth, @city, @country, @phoneNumber);
		
		INSERT INTO Preferences VALUES
		(@@IDENTITY , NULL, @allowPhoneTransfers)
	END
END
GO

DROP PROCEDURE IF EXISTS addNewAccount
GO
CREATE PROCEDURE addNewAccount
@accountID NVARCHAR(100),
@clientID INT,
@name NVARCHAR(100),
@accountType INT,
@password NVARCHAR(100),
@interestRate FLOAT = 1.0,
@frequency NVARCHAR(100) = 'monthly'
AS
BEGIN
	IF LEN(@password) < 20
		RAISERROR('Password not strong enough',17,1);
	ELSE
	BEGIN
		INSERT INTO Accounts VALUES
		(@accountID, @clientID, @name, @accountType, 0, CAST(GETDATE() AS Date), NULL, @password)

		IF (SELECT MainAccount FROM Preferences WHERE ClientID = @clientID) IS NULL
		BEGIN
			UPDATE Preferences
			SET MainAccount = @accountID
			WHERE ClientID = @clientID
		END

		IF @accountType = 3
		BEGIN
			INSERT INTO SavingAccountDetails VALUES
			(@accountID, @interestRate, @frequency)
		END
	END
END
GO


DROP PROCEDURE IF EXISTS disactiveAccount
GO
CREATE PROCEDURE disactiveAccount
@accountID NVARCHAR(100),
@password NVARCHAR(100)
AS
BEGIN
	IF NOT EXISTS (SELECT AccountID FROM Accounts WHERE AccountID = @accountID)
		RAISERROR('Account does not exist',17,1);
	ELSE IF (SELECT EndDate FROM Accounts WHERE AccountID = @accountID) IS NOT NULL
		RAISERROR('Account is disactived',17,1);
	ELSE IF @password <> (SELECT Password FROM Accounts WHERE AccountID = @accountID)
		RAISERROR('Password is not correct',17,1);
	ELSE
	BEGIN
		DECLARE @clientID INT
		SET @clientID = (SELECT A.ClientID FROM Accounts A WHERE A.AccountID = @accountID)
		IF ( SELECT MainAccount FROM Preferences WHERE ClientID = @clientID) = @accountID
		BEGIN
			
			IF (SELECT COUNT(*) FROM Accounts WHERE ClientID = @clientID and AccountID <> @accountID and EndDate IS NULL) > 0
				UPDATE Preferences
				SET MainAccount = ( SELECT TOP 1 AccountID FROM Accounts 
									WHERE ClientID = @clientID and AccountID <> @accountID and EndDate IS NULL)
				WHERE ClientID = @clientID
			ELSE
				UPDATE Preferences
				SET MainAccount = NULL, AllowPhoneTransfer = 0
				WHERE ClientID = @clientID
		END

		UPDATE Accounts
		SET EndDate = CAST(GETDATE() AS Date)
		WHERE AccountID = @accountID
	END
END
GO

DROP PROCEDURE IF EXISTS addNewCard
GO
CREATE PROCEDURE addNewCard
@cardID NVARCHAR(100),
@accountID NVARCHAR(100),
@limit INT,
@pin INT
AS
BEGIN
	IF NOT EXISTS (SELECT AccountID FROM Accounts WHERE AccountID = @accountID)
		RAISERROR('Account does not exist',17,1);
	ELSE IF (SELECT EndDate FROM Accounts WHERE AccountID = @accountID) IS NOT NULL
		RAISERROR('Account has been closed', 17 ,1)
	ELSE IF @limit < 0
		RAISERROR('Incorrect limit',17,1);
	ELSE
		INSERT INTO Cards VALUES
		(@cardID, @accountID, @limit, @pin);
END
GO

DROP PROCEDURE IF EXISTS changeCardLimit
GO
CREATE PROCEDURE changeCardLimit
@cardID NVARCHAR(100),
@limit INT,
@accountID NVARCHAR(100),
@password NVARCHAR(100)
AS
BEGIN
	IF NOT EXISTS (SELECT AccountID FROM Accounts WHERE AccountID = @accountID)
		RAISERROR('Account does not exist',17,1);
	ELSE IF (SELECT EndDate FROM Accounts WHERE AccountID = @accountID) IS NOT NULL
		RAISERROR('Account has been closed', 17 ,1)
	ELSE IF @password <> (SELECT Password FROM Accounts WHERE AccountID = @accountID)
		RAISERROR('Password is not correct',17,1);
	ELSE IF @limit <= 0
		RAISERROR('Incorrect limit',17,1)
	ELSE
		UPDATE Cards
		SET Limit = @limit
		WHERE CardID = @cardID
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
BEGIN
	IF NOT EXISTS (SELECT AccountID FROM Accounts WHERE AccountID = @sender)
		RAISERROR('Account does not exist',17,1);
	ELSE IF (SELECT EndDate FROM Accounts WHERE AccountID = @sender) IS NOT NULL
		RAISERROR('Account has been closed', 17 ,1)
	ELSE IF @amount <= 0
		RAISERROR('Incorrect amount',17,1)
	ELSE IF ( SELECT CurrentBalance
			FROM Accounts
			WHERE AccountID = @sender ) < @amount
		RAISERROR('Not enough funds',17,1)
	ELSE IF @sender = @receiver
		RAISERROR('Incorrect operation',17,1)
	ELSE
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
BEGIN
	IF NOT EXISTS (SELECT AccountID FROM Accounts WHERE AccountID = @sender)
		RAISERROR('Account does not exist',17,1);
	ELSE IF (SELECT EndDate FROM Accounts WHERE AccountID = @sender) IS NOT NULL
		RAISERROR('Account has been closed', 17 ,1)
	ELSE IF @amount <= 0
		RAISERROR('Incorrect amount',17,1)
	ELSE IF ( SELECT CurrentBalance
			FROM Accounts
			WHERE AccountID = @sender ) < @amount
		RAISERROR('Not enough funds',17,1)
	ELSE IF ( SELECT AllowPhoneTransfer
			FROM Preferences P
			JOIN Clients C ON C.ClientID = P.ClientID
			WHERE C.PhoneNumber = @phoneReceiver ) = 0
		RAISERROR('Receiver does not accept phoneTransfers',17,1)
	ELSE IF ( SELECT MainAccount
			FROM Preferences P
			JOIN Clients C ON C.ClientID = P.ClientID
			WHERE C.PhoneNumber = @phoneReceiver ) = @sender
		RAISERROR('Incorrect operation',17,1)
	ELSE
		INSERT INTO PhoneTransfers VALUES
		(@sender, @phoneReceiver, @amount, @title, CAST(GETDATE() AS Date), @category)
END
GO

DROP PROCEDURE IF EXISTS addNewWithdraw
GO
CREATE PROCEDURE addNewWithdraw
@cardID NVARCHAR(100),
@amount MONEY,
@ATM INT
AS
BEGIN
	IF @amount <= 0
		RAISERROR('Incorrect amount',17,1)
	ELSE IF (SELECT EndDate FROM Accounts JOIN Cards ON Account = AccountID WHERE CardID = @cardID) IS NOT NULL
		RAISERROR('Account has been closed', 17 ,1)
	ELSE IF NOT EXISTS(SELECT * FROM ATMs WHERE ATMID = @ATM)
		RAISERROR('ATM does not exist',17,1)
	ELSE IF @amount > (SELECT CurrentBalance FROM ATMs WHERE ATMID = @ATM)
		RAISERROR('ATM does not have enough funds',17,1)	
	ELSE IF @amount > (
		SELECT CurrentBalance
		FROM Accounts A
		JOIN Cards C ON C.Account = A.AccountID
		WHERE C.CardID = @cardID)
		RAISERROR('Not enough funds',17,1)
	ELSE
		INSERT INTO Withdraws VALUES
		(@cardID, @amount, @ATM, GETDATE())
END
GO

DROP PROCEDURE IF EXISTS addNewDeposit
GO
CREATE PROCEDURE addNewDeposit
@cardID NVARCHAR(100),
@amount MONEY,
@ATM INT
AS
BEGIN
	IF @amount <= 0
		RAISERROR('Incorrect amount',17,1)
	ELSE IF (SELECT EndDate FROM Accounts JOIN Cards ON Account = AccountID WHERE CardID = @cardID) IS NOT NULL
		RAISERROR('Account has been closed', 17 ,1)
	ELSE IF NOT EXISTS(SELECT * FROM ATMs WHERE ATMID = @ATM)
		RAISERROR('ATM does not exist',17,1)	
	ELSE
		INSERT INTO Deposits VALUES
		(@cardID, @amount, @ATM, GETDATE())
END
GO

DROP PROCEDURE IF EXISTS addNewTransaction
GO
CREATE PROCEDURE addNewTransaction
@cardID NVARCHAR(100),
@receiver NVARCHAR(100),
@amount MONEY,
@title NVARCHAR(100),
@category INT
AS
BEGIN
	IF @amount <= 0
		RAISERROR('Incorrect amount', 17 ,1)
	ELSE IF (SELECT EndDate FROM Accounts JOIN Cards ON Account = AccountID WHERE CardID = @cardID) IS NOT NULL
		RAISERROR('Account has been closed', 17 ,1)
	ELSE IF @amount > (
		SELECT CurrentBalance
		FROM Accounts A
		JOIN Cards C ON C.Account = A.AccountID
		WHERE C.CardID = @cardID)
		RAISERROR('Not enough funds', 17, 1)
	ELSE IF @amount > (SELECT Limit FROM Cards WHERE CardID = @cardID)
		RAISERROR('Amount greater then card limit',17,1)
	ELSE IF @receiver = (SELECT Account FROM Cards WHERE CardID = @cardID)
		RAISERROR('Incorrect operation', 17, 1)
	ELSE
		INSERT INTO Transactions VALUES
		(@cardID, @receiver, @amount, GETDATE(), @category)
END
GO

DROP PROCEDURE IF EXISTS addNewEmployee
GO
CREATE PROCEDURE addNewEmployee
@name NVARCHAR(100),
@dateOfSign DATE,
@BranchID INT
AS
BEGIN
	IF LEN(@name) < 2
		RAISERROR('To short name', 17, 1)
	ELSE IF @dateOfSign > GETDATE()
		RAISERROR('Date can not be in the future', 17, 1)
	ELSE
		INSERT INTO Employees VALUES
		(@name, @dateOfSign, @BranchID)
END
GO

DROP PROCEDURE IF EXISTS addNewBranches
GO
CREATE PROCEDURE addNewBranches
@name NVARCHAR(100),
@city NVARCHAR(100),
@country NVARCHAR(100)
AS
BEGIN
	IF LEN(@name) < 2 OR LEN(@city) < 2 OR LEN(@city) < 2
		RAISERROR('To short parameters', 17, 1)
	ELSE
		INSERT INTO Branches VALUES
		(@name, @city, @country)
END
GO

DROP PROCEDURE IF EXISTS addNewATM
GO
CREATE PROCEDURE addNewATM
@currentBalance INT,
@supervisorDepartment INT,
@city NVARCHAR(100)
AS
BEGIN
	IF LEN(@city) < 2
		RAISERROR('To short city name', 17, 1)
	ELSE IF @currentBalance < 0
		RAISERROR('Incorrect current balance', 17, 1)
	ELSE
		INSERT INTO ATMs VALUES
		(@currentBalance, @supervisorDepartment, @city)
END
GO

DROP PROCEDURE IF EXISTS addNewTransactionCategory
GO
CREATE PROCEDURE addNewTransactionCategory
@description NVARCHAR(100)
AS
BEGIN
	IF LEN(@description) >= 2
		INSERT INTO TransactionCategories VALUES
		(@description)
	ELSE
		RAISERROR('To short description', 17, 1)
END
GO

DROP PROCEDURE IF EXISTS addNewAccountType
GO
CREATE PROCEDURE addNewAccountType
@description NVARCHAR(100)
AS
BEGIN
	IF LEN(@description) >= 2
		INSERT INTO AccountTypes VALUES
		(@description)
	ELSE
		RAISERROR('To short description', 17, 1)
END
GO

DROP PROCEDURE IF EXISTS addNewLoan
GO
CREATE PROCEDURE addNewLoan
@accountID NVARCHAR(100),
@amount MONEY,
@endDate DATE,
@servingEmployee INT
AS
BEGIN
	IF NOT EXISTS (SELECT AccountID FROM Accounts WHERE AccountID = @accountID)
		RAISERROR('Account does not exist',17,1);
	ELSE IF (SELECT EndDate FROM Accounts WHERE AccountID = @accountID) IS NOT NULL
		RAISERROR('Account has been closed', 17 ,1)
	ELSE IF (SELECT AccountType FROM Accounts WHERE AccountID = @accountID) = 2
		RAISERROR('Incorrect account type', 17 ,1)
	ELSE IF @amount <= 0
		RAISERROR('Incorrect amount', 17 ,1)
	ELSE IF NOT EXISTS(SELECT * FROM Employees WHERE EmployeeID = @servingEmployee)
		RAISERROR('Employee does not exist',17,1)
	ELSE IF @endDate < GETDATE()
		RAISERROR('Date can not be in the past', 17, 1)
	ELSE
		INSERT INTO Loans VALUES
		(@accountID, @amount, GETDATE(), @endDate, @servingEmployee)
END
GO

DROP PROCEDURE IF EXISTS reportATMsMalfunction
GO
CREATE PROCEDURE reportATMsMalfunction
@ATMID INT,
@description NVARCHAR(100),
@reportingEmployee INT
AS
BEGIN
	IF NOT EXISTS(SELECT * FROM ATMs WHERE ATMID = @ATMID)
		RAISERROR('ATM does not exist',17,1)
	ELSE IF NOT EXISTS(SELECT * FROM Employees WHERE EmployeeID = @reportingEmployee)
		RAISERROR('Employee does not exist',17,1)
	ELSE
		INSERT INTO ATMsMalfunctions VALUES
		(@ATMID, @description, GETDATE(), @reportingEmployee)
END
GO

DROP PROCEDURE IF EXISTS addStandingOrders
GO
CREATE PROCEDURE addStandingOrders
@sender NVARCHAR(100),
@receiver NVARCHAR(100),
@amount MONEY,
@title NVARCHAR(100),
@frequency INT,
@startDate DATE,
@endDate DATE
AS
BEGIN
	IF NOT EXISTS (SELECT AccountID FROM Accounts WHERE AccountID = @sender)
		RAISERROR('Account does not exist',17,1);
	ELSE IF (SELECT EndDate FROM Accounts WHERE AccountID = @sender) IS NOT NULL
		RAISERROR('Account has been closed', 17 ,1)
	ELSE IF @sender = @receiver OR @endDate = @startDate
		RAISERROR('Incorrect operation',17,1)
	ELSE IF @amount <= 0
		RAISERROR('Incorrect amount',17,1)
	ELSE IF @frequency <= 0 OR @frequency > (DATEDIFF(day, @startDate, @endDate))
		RAISERROR('Incorrect frequency',17,1) 
	ELSE IF @startDate < GETDATE()
		RAISERROR('Start date can not be in the past', 17, 1)
	ELSE IF @endDate < GETDATE()
		RAISERROR('End date can not be in the past', 17, 1)
	ELSE
		INSERT INTO StandingOrders VALUES
		(@sender, @receiver, @amount, @title, @frequency, @startDate, @endDate)
END
GO