
USE [master]
GO

/****** Object:  ResourcePool [Support]    Script Date: 8/24/2015 4:16:48 PM ******/
CREATE RESOURCE POOL [Support] WITH(min_cpu_percent=0, 
		max_cpu_percent=25, 
		min_memory_percent=0, 
		max_memory_percent=100, 
		cap_cpu_percent=100, 
		AFFINITY SCHEDULER = AUTO,
		MIN_IOPS_PER_VOLUME=0, 
		max_iops_per_volume=0)

GO


/****** Object:  WorkloadGroup [Support]    Script Date: 8/24/2015 4:12:19 PM ******/
CREATE WORKLOAD GROUP [SupportReadOnly] WITH(group_max_requests=0, 
		importance=Low, 
		request_max_cpu_time_sec=0, 
		request_max_memory_grant_percent=25, 
		request_memory_grant_timeout_sec=0, 
		max_dop=2) USING [Support]
GO

CREATE FUNCTION udf_Resource_Governor_Funct ()
RETURNS sysname
    WITH SCHEMABINDING
AS
BEGIN

    DECLARE @Workload_Group sysname;

    IF (IS_MEMBER('ICEENTERPRISE\SG_SQL_ProdSupportReadOnly') = 1)
        SET @Workload_Group = 'SupportReadOnly';
    ELSE
        SET @Workload_Group = 'default';

    RETURN @Workload_Group;

END;

go

ALTER RESOURCE GOVERNOR
WITH (CLASSIFIER_FUNCTION=dbo.udf_Resource_Governor_Funct);
GO
ALTER RESOURCE GOVERNOR RECONFIGURE
GO