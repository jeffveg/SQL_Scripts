use neo_prod_old;
drop table if exists #CDC_Props;
declare @Output nvarchar(max)
create table #CDC_Props (source_schema sysname
                       , source_table sysname
                       , capture_instance sysname
                       , object_id int
                       , source_object_id int
                       , start_lsn binary(10)
                       , end_lsn binary(10)
                       , supports_net_changes bit
                       , has_drop_pending bit
                       , role_name sysname
                       , filegroup_name sysname
                       , index_name sysname
                       , create_date datetime
                       , index_column_list nvarchar(max)
                       , captured_column_list nvarchar(max));

insert into #CDC_Props (source_schema
                      , source_table
                      , capture_instance
                      , object_id
                      , source_object_id
                      , start_lsn
                      , end_lsn
                      , supports_net_changes
                      , has_drop_pending
                      , role_name
                      , filegroup_name
                      , index_name
                      , create_date
                      , index_column_list
                      , captured_column_list)
exec sys.sp_cdc_help_change_data_capture;



DECLARE cCDC CURSOR FAST_FORWARD READ_ONLY FOR
select 'EXEC sys.sp_cdc_enable_table '
     + char(13) + char(10) + ' @source_schema = N''' + [source_schema] + ''''
     + char(13) + char(10) + ', @source_name = N''' + [source_table] + ''''
	 + char(13) + char(10) + ', @role_name = N''' + [role_name] + ''''
     + char(13) + char(10) + ', @index_name = N''' + [index_name] + ''''
     + char(13) + char(10) + ', @captured_column_list = N''' + [captured_column_list] + ''''
     + char(13) + char(10) + ', @filegroup_name = N''' + [filegroup_name] + ''''
	 + char(13) + char(10) + ', @supports_net_changes = 1; '
     + char(13) + char(10) + ' GO'
from #CDC_Props;

OPEN cCDC

FETCH NEXT FROM cCDC INTO @Output

WHILE @@FETCH_STATUS = 0
BEGIN
 print @Output;

    FETCH NEXT FROM cCDC INTO @Output
END

CLOSE cCDC
DEALLOCATE cCDC
