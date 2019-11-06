/****** Object:  StoredProcedure [dbo].[sp_TurnOffRoundRobin]    Script Date: 3/12/2019 10:42:19 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROC [dbo].[sp_TurnOffRoundRobin] 

AS


ALTER AVAILABILITY GROUP [us-sv-dw] 
  MODIFY REPLICA ON
  N'us-sv-dw05' WITH 
  (PRIMARY_ROLE (READ_ONLY_ROUTING_LIST=(('us-sv-dw06','us-sv-dw08'),'us-sv-dw05')));

GO
