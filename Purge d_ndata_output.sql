

declare @BatchSize int = 1000;

--print convert(varchar(20),getdate(),120)
--begin transaction;
--update top (@BatchSize)
--    ndo
--set final_output = null
--  , debug = null
--from d_ndata_output             ndo
--    inner join d_image_index    di
--        on ndo.image_index_id = di.image_index_id
--    inner join d_image_fileinfo fi
--        on di.company_id = fi.Company_ID
--           and di.company_image_num = fi.Company_Image_Num
--where ndo.updated_date < dateadd(day, -90, getdate())
--      and ndo.final_output is not null
--      and ndo.debug is not null option (maxdop 1);
--print convert(varchar(20),getdate(),120)
--rollback;







print convert(varchar(20),getdate(),120)

set nocount on

/* declare variables */
declare @ndata_output_id int
      , @Counter         int;

declare cPurgenData cursor fast_forward read_only for
select top (@BatchSize)
    ndo.ndata_output_id
from d_ndata_output             ndo
    inner join d_image_index    di
        on ndo.image_index_id = di.image_index_id
    inner join d_image_fileinfo fi
        on di.company_id = fi.Company_ID
           and di.company_image_num = fi.Company_Image_Num
where ndo.updated_date < dateadd(day, -90, getdate())
      and ndo.final_output is not null
      and ndo.debug is not null;

set @Counter = 1;
begin transaction;
open cPurgenData;

fetch next from cPurgenData
into @ndata_output_id;
while @@fetch_status = 0
begin

    update dbo.d_ndata_output
    set final_output = null
      , debug = null
    where ndata_output_id = @ndata_output_id;

    if @Counter % 1000 = 0
    begin
        print @Counter;
    end;

    set @Counter = @Counter + 1;

    fetch next from cPurgenData
    into @ndata_output_id;
end;
print convert(varchar(20),getdate(),120)
rollback;

close cPurgenData;
deallocate cPurgenData;

print convert(varchar(20),getdate(),120)