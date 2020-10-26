CREATE FUNCTION [dbo].[fn_getQuarterStarteDate](@QuarterString VARCHAR(20) = 'Current')
    RETURNS DATE
    AS
BEGIN
	declare @date AS DATETIME
	IF @QuarterString = 'Previous'
		SET @date = DATEADD(month, -3, GETDATE())
	ELSE IF @QuarterString = 'Next'
		SET @date = DATEADD(month, 3, GETDATE())
	ELSE
		SET @date = GETDATE()

	IF MONTH(@date) in (1, 2, 3)
		BEGIN
			RETURN DATEFROMPARTS(YEAR(@date), 1, 1)
		END
	if MONTH(@date) in (4, 5, 6)
		BEGIN
			RETURN DATEFROMPARTS(YEAR(@date), 4, 1)
		END
	if MONTH(@date) in (7, 8, 9)
		BEGIN
			RETURN DATEFROMPARTS(YEAR(@date), 7, 1)
		END
	if MONTH(@date) in (10, 11, 12)
		BEGIN
			RETURN DATEFROMPARTS(YEAR(@date), 10, 1)
		END
	RETURN DATEFROMPARTS(YEAR(@date), MONTH(@date), 1)
END
