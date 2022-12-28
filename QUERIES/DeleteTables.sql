-- throws lot of errors cause of constraints but ignore it
-- after 3 loops it deletes all tables

DECLARE @i INT = 0;
WHILE @i < 3
BEGIN
    IF OBJECT_ID('Accounts', 'U') IS NOT NULL
        DROP TABLE [Accounts]
    IF OBJECT_ID('AccountTypes', 'U') IS NOT NULL
        DROP TABLE [AccountTypes]
    IF OBJECT_ID('ATMs', 'U') IS NOT NULL
        DROP TABLE [ATMs]
    IF OBJECT_ID('ATMsMalfunctions', 'U') IS NOT NULL
        DROP TABLE [ATMsMalfunctions]
    IF OBJECT_ID('Cards', 'U') IS NOT NULL
        DROP TABLE [Cards]
    IF OBJECT_ID('Clients', 'U') IS NOT NULL
        DROP TABLE [Clients]
    IF OBJECT_ID('Departments', 'U') IS NOT NULL
        DROP TABLE [Departments]
    IF OBJECT_ID('Deposits', 'U') IS NOT NULL
        DROP TABLE [Deposits]
    IF OBJECT_ID('Employees', 'U') IS NOT NULL
        DROP TABLE [Employees]
    IF OBJECT_ID('Loans', 'U') IS NOT NULL
        DROP TABLE [Loans]
    IF OBJECT_ID('PhoneTransfers', 'U') IS NOT NULL
        DROP TABLE [PhoneTransfers]
    IF OBJECT_ID('Preferences', 'U') IS NOT NULL
        DROP TABLE [Preferences]
    IF OBJECT_ID('SavingAccountDetails', 'U') IS NOT NULL
        DROP TABLE [SavingAccountDetails]
    IF OBJECT_ID('StandingOrders', 'U') IS NOT NULL
        DROP TABLE [StandingOrders]
    IF OBJECT_ID('TransactionCategories', 'U') IS NOT NULL
        DROP TABLE [TransactionCategories]
    IF OBJECT_ID('Transactions', 'U') IS NOT NULL
        DROP TABLE [Transactions]
    IF OBJECT_ID('Transfers', 'U') IS NOT NULL
        DROP TABLE [Transfers]
    IF OBJECT_ID('Withdraws', 'U') IS NOT NULL
        DROP TABLE [Withdraws]
    
    SET @i = @i + 1;
END;