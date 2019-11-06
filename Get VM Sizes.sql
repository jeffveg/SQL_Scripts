
/* Run this on US-SV-VCenter01 in the VIM_SQL database */
SELECT  g.DNS_NAME AS GuestName       
       ,g.MEM_SIZE_MB GuestMemMBConfigured
       ,g.NUM_VCPU GuestCoreCount
       ,H.DNS_NAME HostName
FROM    VPX_VM g
JOIN    dbo.VPX_HOST H
        ON g.HOST_ID = H.ID
WHERE   H.DATACENTER_ID = 532
        AND g.IS_TEMPLATE = 0
       AND g.POWER_STATE = 1
ORDER BY HostName
       ,GuestName;

SELECT  H.DNS_NAME AS HostName
       ,s.NumOfGuests
       ,H.CPU_THREAD_COUNT AS HostCoreCount
       ,SumGuestCoreCount
       ,CAST(SumGuestCoreCount / CAST(H.CPU_THREAD_COUNT AS FLOAT) * 100 AS SMALLMONEY) AS PcentCoresUsed
       ,CAST(H.MEM_SIZE AS BIGINT) / 1024 / 1024 HostMemMB
       ,SumGuestMemMB SumGuestMemMBConfigured
       ,CAST(SumGuestMemMB / ( CAST(H.MEM_SIZE AS FLOAT) / 1024 / 1024 ) * 100 AS SMALLMONEY) AS PCentMemoryUsed
FROM    dbo.VPX_HOST H
JOIN    ( SELECT    COUNT(*) NumOfGuests
                   ,SUM(MEM_SIZE_MB) SumGuestMemMB
                   ,SUM(NUM_VCPU) SumGuestCoreCount
                   ,HOST_ID
          FROM      VPX_VM g
          WHERE     DATACENTER_ID = 532
                    AND g.IS_TEMPLATE = 0
                    AND g.POWER_STATE = 1
          GROUP BY  g.HOST_ID
        ) s
        ON s.HOST_ID = H.ID
WHERE   H.DATACENTER_ID = 532 ORDER BY HostName;



SELECT  SUM(H.CPU_THREAD_COUNT) AS TotalHostCoreCount
       ,SUM(SumGuestCoreCount) AS TotalGuestCoreCount
       ,SUM(CAST(H.MEM_SIZE AS BIGINT) / 1024 / 1024) TotalHostMemMB
       ,SUM(SumGuestMemMB) AS TotalGuestMemoryMBConfigured
       ,SUM(NumOfGuests) AS TotalNumGuests
FROM    dbo.VPX_HOST H
JOIN    ( SELECT    COUNT(*) NumOfGuests
                   ,SUM(MEM_SIZE_MB) SumGuestMemMB
                   ,SUM(NUM_VCPU) SumGuestCoreCount
                   ,HOST_ID
          FROM      VPX_VM g
          WHERE     DATACENTER_ID = 532
                    AND g.IS_TEMPLATE = 0
                   AND g.POWER_STATE = 1
          GROUP BY  g.HOST_ID
        ) s
        ON s.HOST_ID = H.ID
WHERE   H.DATACENTER_ID = 532;