CREATE PROCEDURE addNewClient
@name NVARCHAR(100),
@dateOfBirth DATE,
@city NVARCHAR(100),
@country NVARCHAR(100),
@phoneNumber NVARCHAR(100)
AS
BEGIN
    INSERT INTO Clients VALUES
    (@name, @dateOfBirth, @city, @country, @phoneNumber)
END