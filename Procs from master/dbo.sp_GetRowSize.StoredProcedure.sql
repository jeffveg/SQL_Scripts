/****** Object:  StoredProcedure [dbo].[sp_GetRowSize]    Script Date: 3/12/2019 10:42:19 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[sp_GetRowSize](@Tablename varchar(100),@pkcol varchar(100))
AS 
BEGIN
declare @dynamicsql varchar(1000)

-- A @pkcol can be used to identify max/min length row
set @dynamicsql = 'select ' + @PkCol +' , (0'

-- traverse each record and calculate the datalength
select @dynamicsql = @dynamicsql + ' + isnull(datalength(' + name + '), 1)' 
	from syscolumns where id = object_id(@Tablename)
set @dynamicsql = @dynamicsql + ') as rowsize from ' + @Tablename + ' order by 1'


exec (@dynamicsql)

END
GO
