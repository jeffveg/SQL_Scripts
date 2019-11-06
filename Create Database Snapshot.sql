/* Be sure to be in the database you are creating the snapshot from*/

declare @Create varchar(max);

set @Create
    = 'CREATE DATABASE ' + db_name() + '_ss' + format(getdate(), 'yyyyMMdd_HHmm') + ' ON '
      +
      (
          select (stuff(
                  (
                      select ', ' + '(NAME = ' + [name] + ', FILENAME = '''
                             + reverse(substring(reverse([filename]), patindex('%[\]%', reverse([filename])), 100))
                             + [name] + '_' + format(getdate(), 'yyyyMMdd_HHmm') + '.ss'')'
                      from sysfiles
                      where groupid in ( 1, 4, 3 )
                      for xml path('')
                  )
                , 1
                , 2
                , ''
                       )
                 ) as StringValue
      ) + ' AS SNAPSHOT OF ' + db_name();


print @Create;
exec (@Create);