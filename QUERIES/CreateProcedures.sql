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

		IF @accountType = 2
		BEGIN
			INSERT INTO SavingAccountDetails VALUES
			(@accountID, @interestRate, @frequency)
		END
	END
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
BEGIN
	IF (SELECT EndDate FROM Accounts WHERE AccountID = @account) IS NOT NULL
			RAISERROR('Account has been closed', 17 ,1)
	ELSE IF @limit < 0
		RAISERROR('Incorrect limit',17,1);
	ELSE
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
BEGIN
	IF @amount <= 0
		RAISERROR('Incorrect amount',17,1)
	ELSE IF (SELECT EndDate FROM Accounts WHERE AccountID = @sender) IS NOT NULL
			RAISERROR('Account has been closed', 17 ,1)
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
	IF @amount <= 0
		RAISERROR('Incorrect amount',17,1)
	ELSE IF (SELECT EndDate FROM Accounts WHERE AccountID = @sender) IS NOT NULL
			RAISERROR('Account has been closed', 17 ,1)
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
GO

DROP PROCEDURE IF EXISTS addNewEmployee
GO
CREATE PROCEDURE addNewEmployee
@name NVARCHAR(100),
@dateOfSign DATE,
@departmentID INT
AS
BEGIN
	IF LEN(@name) < 2
		RAISERROR('To short name', 17, 1)
	ELSE
		INSERT INTO Employees VALUES
		(@name, @dateOfSign, @departmentID)
END
GO

DROP PROCEDURE IF EXISTS addNewDepartments
GO
CREATE PROCEDURE addNewDepartments
@name NVARCHAR(100),
@city NVARCHAR(100),
@country NVARCHAR(100)
AS
BEGIN
	IF LEN(@name) < 2 OR LEN(@city) < 2 OR LEN(@city) < 2
		RAISERROR('To short parameters', 17, 1)
	ELSE
		INSERT INTO Departments VALUES
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

DROP PROCEDURE IF EXISTS makeLoan
GO
CREATE PROCEDURE makeLoan
@accountID NVARCHAR(100),
@amount MONEY,
@endDate DATE,
@servingEmployee INT
AS
BEGIN
	IF @amount <= 0
		RAISERROR('Incorrect amount', 17 ,1)
	ELSE IF (SELECT EndDate FROM Accounts WHERE AccountID = @accountID) IS NOT NULL
		RAISERROR('Account has been closed', 17 ,1)
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