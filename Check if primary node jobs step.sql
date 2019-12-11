declare @AGName sysname, @RunIfPrimary bit;

set @AGName = null; -- if there is more than one AG on the server set the name AG name here
set @RunIfPrimary = 'TRUE';

/* Below with check the role of the server and error depending on the setting above */
declare @Role int
select @Role = hars.role
from sys.dm_hadr_availability_replica_states as hars
    join sys.dm_hadr_name_id_map as map
        on hars.group_id = map.ag_id
    join sys.availability_replicas as ar
        on hars.replica_id = ar.replica_id
where hars.is_local = 1 and hars.operational_state = 2 and map.ag_name = isnull(@AGName, map.ag_name);


declare @MSG nvarchar(100);

if @Role = 1 and @RunIfPrimary = 'FALSE'
begin
    set @MSG = 'This the primary node for ' + isnull(@AGName, 'default') + ' and RunIfPrimary is False.';
    raiserror(@MSG, 16, 1);
end;

if @Role = 2 and @RunIfPrimary = 'TRUE'
begin
    set @MSG = 'This the primary node for ' + isnull(@AGName, 'default') + ' and RunIfPrimary is True.';
    raiserror(@MSG, 16, 1);
end;

