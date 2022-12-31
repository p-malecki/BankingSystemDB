CREATE TABLE [Clients] (
  [ClientID] INT IDENTITY PRIMARY KEY,
  [Name] NVARCHAR(100),
  [DateOfBirth] DATE,
  [City] NVARCHAR(100),
  [Country] NVARCHAR(100),
  [PhoneNumber] NVARCHAR(100) UNIQUE
)

CREATE TABLE [AccountTypes] (
  [AccountType] INT IDENTITY PRIMARY KEY,
  [Description] NVARCHAR(100)
)

CREATE TABLE [Accounts] (
  [AccountID] NVARCHAR(100) PRIMARY KEY,
  [ClientID] INT FOREIGN KEY REFERENCES [Clients] ([ClientID]),
  [Name] NVARCHAR(100),
  [AccountType] INT FOREIGN KEY REFERENCES [AccountTypes] ([AccountType]),
  [CurrentBalance] INT,
  [StartDate] DATE,
  [EndDate] DATE,
  [Password] NVARCHAR(100)
)

CREATE TABLE [Cards] (
  [CardID] NVARCHAR(100) PRIMARY KEY,
  [Account] NVARCHAR(100) FOREIGN KEY REFERENCES [Accounts] ([AccountID]),
  [Limit] INT,
  [PIN] INT
)

CREATE TABLE [Preferences] (
  [ClientID] INT PRIMARY KEY REFERENCES [Clients] ([ClientID]),
  [MainAccount] NVARCHAR(100) FOREIGN KEY REFERENCES [Accounts] ([AccountID]) ,
  [AllowPhoneTransfer] BIT
)

CREATE TABLE [SavingAccountDetails] (
  [AccountID] NVARCHAR(100) PRIMARY KEY REFERENCES [Accounts] ([AccountID]),
  [InterestRate] NVARCHAR(100),
  [Frequency] FLOAT
)

CREATE TABLE [Departments] (
  [DepartmentID] INT IDENTITY PRIMARY KEY,
  [Name] NVARCHAR(100),
  [City] NVARCHAR(100),
  [Country] NVARCHAR(100)
)

CREATE TABLE [Employees] (
  [EmployeeID] INT IDENTITY PRIMARY KEY,
  [Name] NVARCHAR(100),
  [DateOfSign] DATE,
  [DepartmentID] INT FOREIGN KEY REFERENCES [Departments] ([DepartmentID])
)

CREATE TABLE [Loans] (
  [LoanID] INT IDENTITY PRIMARY KEY,
  [AccountID] NVARCHAR(100) FOREIGN KEY REFERENCES [Accounts] ([AccountID]),
  [Amount] MONEY,
  [StartDate] DATE,
  [EndDate] DATE,
  [ServingEmployee] INT FOREIGN KEY REFERENCES [Employees] ([EmployeeID])
)

CREATE TABLE [ATMs] (
  [ATMID] INT IDENTITY PRIMARY KEY,
  [CurrentBalance] INT,
  [SupervisorDepartment] INT REFERENCES [Departments] ([DepartmentID]),
  [City] NVARCHAR(100)
)

CREATE TABLE [ATMsMalfunctions] (
  [ReportID] INT IDENTITY PRIMARY KEY,
  [ATMID] INT FOREIGN KEY REFERENCES [ATMs] ([ATMID]),
  [Description] NVARCHAR(100),
  [Date] DATE,
  [ReportingEmployee] INT FOREIGN KEY REFERENCES [Employees] ([EmployeeID])
)

CREATE TABLE [Withdraws] (
  [OperationID] INT IDENTITY PRIMARY KEY,
  [Card] NVARCHAR(100) FOREIGN KEY REFERENCES [Cards] ([CardID]),
  [Amount] MONEY,
  [ATMID] INT FOREIGN KEY REFERENCES [ATMs] ([ATMID]),
  [Date] DATE
)

CREATE TABLE [Deposits] (
  [OperationID] INT IDENTITY PRIMARY KEY,
  [Card] NVARCHAR(100) FOREIGN KEY REFERENCES [Cards] ([CardID]),
  [Amount] MONEY,
  [ATMID] INT FOREIGN KEY REFERENCES [ATMs] ([ATMID]),
  [Date] DATE
)

CREATE TABLE [TransactionCategories] (
  [CategoryID] INT IDENTITY PRIMARY KEY,
  [Description] NVARCHAR(100)
)

CREATE TABLE [StandingOrders] (
  [StandingOrdersID] INT IDENTITY PRIMARY KEY,
  [Sender] NVARCHAR(100) FOREIGN KEY REFERENCES [Accounts] ([AccountID]),
  [Receiver] NVARCHAR(100),
  [Amount] MONEY,
  [Title] NVARCHAR(100),
  [Frequency] INT,
  [StartDate] DATE,
  [EndDate] DATE
)

CREATE TABLE [Transfers] (
  [TransferID] INT IDENTITY PRIMARY KEY,
  [Sender] NVARCHAR(100) FOREIGN KEY REFERENCES [Accounts] ([AccountID]),
  [Receiver] NVARCHAR(100),
  [Amount] MONEY,
  [Title] NVARCHAR(100),
  [Date] DATE,
  [Category] INT FOREIGN KEY REFERENCES [TransactionCategories] ([CategoryID]),
  [StandingOrder] INT FOREIGN KEY REFERENCES [StandingOrders] ([StandingOrdersID])
)

CREATE TABLE [Transactions] (
  [TransactionID] INT IDENTITY PRIMARY KEY,
  [UsedCard] NVARCHAR(100) FOREIGN KEY REFERENCES [Cards] ([CardID]),
  [Receiver] NVARCHAR(100),
  [Amount] MONEY,
  [Date] DATE,
  [Category] INT FOREIGN KEY REFERENCES [TransactionCategories] ([CategoryID])
)

CREATE TABLE [PhoneTransfers] (
  [TransferID] INT IDENTITY PRIMARY KEY,
  [Sender] NVARCHAR(100) FOREIGN KEY REFERENCES [Accounts] ([AccountID]),
  [PhoneReceiver] NVARCHAR(100),
  [Amount] MONEY,
  [Title] NVARCHAR(100),
  [Date] DATE,
  [Category] INT FOREIGN KEY REFERENCES [TransactionCategories] ([CategoryID])
)