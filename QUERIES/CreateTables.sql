CREATE TABLE [Clients] (
  [ClientID] INT PRIMARY KEY,
  [Name] NVARCHAR,
  [DateOfBirth] DATE,
  [City] NVARCHAR,
  [Country] NVARCHAR,
  [PhoneNumber] INT UNIQUE
)

CREATE TABLE [AccountTypes] (
  [AccountType] INT PRIMARY KEY,
  [Description] NVARCHAR
)

CREATE TABLE [Accounts] (
  [AccountID] INT PRIMARY KEY,
  [ClientID] INT FOREIGN KEY REFERENCES [Clients] ([ClientID]),
  [Name] NVARCHAR,
  [AccountType] INT FOREIGN KEY REFERENCES [AccountTypes] ([AccountType]),
  [CurrentBalance] MONEY
)

CREATE TABLE [Cards] (
  [CardID] INT PRIMARY KEY,
  [Account] INT FOREIGN KEY REFERENCES [Accounts] ([AccountID]),
  [Limit] INT,
  [PIN] INT
)

CREATE TABLE [Preferences] (
  [ClientID] INT PRIMARY KEY REFERENCES [Clients] ([ClientID]),
  [MainAccount] INT FOREIGN KEY REFERENCES [Accounts] ([AccountID]) ,
  [AllowPhoneTransfer] BIT
)

CREATE TABLE [SavingAccountDetails] (
  [AccountID] INT PRIMARY KEY REFERENCES [Accounts] ([AccountID]),
  [InterestRate] INT,
  [Frequency] INT
)

CREATE TABLE [Departments] (
  [DepartmentID] INT PRIMARY KEY,
  [Name] NVARCHAR,
  [City] NVARCHAR,
  [Country] NVARCHAR
)

CREATE TABLE [Employees] (
  [EmployeeID] INT PRIMARY KEY,
  [Name] NVARCHAR,
  [DateOfSign] DATE,
  [DepartmentID] INT FOREIGN KEY REFERENCES [Departments] ([DepartmentID])
)

CREATE TABLE [Loans] (
  [LoanID] INT PRIMARY KEY,
  [AccountID] INT FOREIGN KEY REFERENCES [Accounts] ([AccountID]),
  [Amount] MONEY,
  [StartDate] DATE,
  [EndDate] DATE,
  [ServingEmployee] INT FOREIGN KEY REFERENCES [Employees] ([EmployeeID])
)

CREATE TABLE [ATMs] (
  [ATMID] INT PRIMARY KEY,
  [CurrentBalance] INT,
  [SupervisorDepartment] INT REFERENCES [Departments] ([DepartmentID]),
  [City] NVARCHAR
)

CREATE TABLE [ATMsMalfunctions] (
  [ReportID] INT PRIMARY KEY,
  [ATMID] INT FOREIGN KEY REFERENCES [ATMs] ([ATMID]),
  [Description] NVARCHAR,
  [Date] DATE,
  [ReportingEmployee] INT FOREIGN KEY REFERENCES [Employees] ([EmployeeID])
)

CREATE TABLE [Withdraws] (
  [OperationID] INT PRIMARY KEY,
  [Card] INT FOREIGN KEY REFERENCES [Cards] ([CardID]),
  [Amount] INT,
  [ATMID] INT FOREIGN KEY REFERENCES [ATMs] ([ATMID]),
  [Date] DATE
)

CREATE TABLE [Deposits] (
  [OperationID] INT PRIMARY KEY,
  [Card] INT FOREIGN KEY REFERENCES [Cards] ([CardID]),
  [Amount] INT,
  [ATMID] INT FOREIGN KEY REFERENCES [ATMs] ([ATMID]),
  [Date] DATE
)

CREATE TABLE [TransactionCategories] (
  [CategoryID] INT PRIMARY KEY,
  [Description] NVARCHAR
)

CREATE TABLE [StandingOrders] (
  [StandingOrdersID] INT PRIMARY KEY,
  [Sender] INT FOREIGN KEY REFERENCES [Accounts] ([AccountID]),
  [Receiver] INT,
  [Amount] MONEY,
  [Title] NVARCHAR,
  [Frequency] INT,
  [StartDate] DATE,
  [EndDate] DATE
)

CREATE TABLE [Transfers] (
  [TransferID] INT PRIMARY KEY,
  [Sender] INT FOREIGN KEY REFERENCES [Accounts] ([AccountID]),
  [Receiver] INT,
  [Amount] MONEY,
  [Title] NVARCHAR,
  [Date] DATE,
  [Category] INT FOREIGN KEY REFERENCES [TransactionCategories] ([CategoryID]),
  [StandingOrder] INT FOREIGN KEY REFERENCES [StandingOrders] ([StandingOrdersID])
)

CREATE TABLE [Transactions] (
  [TransactionID] INT PRIMARY KEY,
  [UsedCard] INT FOREIGN KEY REFERENCES [Cards] ([CardID]),
  [Receiver] INT,
  [Amount] INT,
  [Date] DATE,
  [Category] INT FOREIGN KEY REFERENCES [TransactionCategories] ([CategoryID])
)

CREATE TABLE [PhoneTransfers] (
  [TransferID] INT PRIMARY KEY,
  [Sender] INT FOREIGN KEY REFERENCES [Accounts] ([AccountID]),
  [PhoneReceiver] INT FOREIGN KEY REFERENCES [Clients] ([PhoneNumber]),
  [Amount] INT,
  [Title] NVARCHAR,
  [Date] DATE,
  [Category] INT FOREIGN KEY REFERENCES [TransactionCategories] ([CategoryID])
)