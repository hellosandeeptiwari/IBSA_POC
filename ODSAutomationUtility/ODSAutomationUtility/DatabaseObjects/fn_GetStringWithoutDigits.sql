
CREATE OR ALTER FUNCTION [dbo].[fn_GetStringWithoutDigits](@strInput VARCHAR(400))
RETURNS VARCHAR(400)
AS
BEGIN

    WHILE PATINDEX('%[0-9]%', @strInput) > 0
        SET @strInput = STUFF(@strInput, PATINDEX('%[0-9]%', @strInput), 1, '')

    RETURN @strInput
END
