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