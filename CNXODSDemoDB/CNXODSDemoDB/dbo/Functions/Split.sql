
CREATE FUNCTION [dbo].[Split]
(
@String NVARCHAR(4000),
@Delimiter NCHAR(1)
)
RETURNS @Strings TABLE
(
	Id INT,
	Data NVARCHAR(2000)
) 
AS
BEGIN 

if LEFT(@String, 1) = ';'
	set @String = right(@String, len(@String) -1);

if RIGHT(@String, 1) = ';'
	set @String = LEFT(@String, len(@String) -1);


WITH Split(stpos,endpos) 
AS(
SELECT 0 AS stpos, CHARINDEX(@Delimiter,@String) AS endpos
UNION ALL
SELECT endpos+1, CHARINDEX(@Delimiter,@String,endpos+1)
FROM Split
WHERE endpos > 0
)
INSERT INTO @Strings(Id, Data)
SELECT 'Id' = ROW_NUMBER() OVER (ORDER BY (SELECT 1)),
'Data' = SUBSTRING(@String,stpos,COALESCE(NULLIF(endpos,0),LEN(@String)+1)-stpos)
FROM Split;

RETURN

END
