DECLARE @DeploymentID UNIQUEIDENTIFIER = NULL,  --SELECT NEWID() to generate a new uniqueidentifier
		@ScriptName VARCHAR(100) = NULL, --Naming Standard: [TicketNumber]_[DatabaseName]_Data.sql
		@ShortDescription VARCHAR(255) = NULL, --A short description of the change
		@TicketURL VARCHAR(255) = NULL --Full URL of the ticket (JIRA or VersionOne)

IF NOT EXISTS(SELECT DeploymentID FROM SourceControl_DataDeployment WHERE DeploymentID = @DeploymentID) BEGIN
	INSERT INTO SourceControl_DataDeployment (DeploymentID, ScriptName, ShortDescription,TicketURL)VALUES(@DeploymentID, @ScriptName, @ShortDescription, @TicketURL)
END

IF EXISTS (SELECT DeploymentID FROM SourceControl_DataDeployment WHERE DeploymentID = @DeploymentID AND Deployed = 1) 
	SET NOEXEC ON

BEGIN TRY
	BEGIN TRANSACTION

/****************************************************************************************************************************
											  DATA CHANGE BEGIN
****************************************************************************************************************************/






/****************************************************************************************************************************
												DATA CHANGE END
****************************************************************************************************************************/

	UPDATE SourceControl_DataDeployment SET Deployed = 1 WHERE DeploymentID = @DeploymentID
	COMMIT

END TRY
BEGIN CATCH
	ROLLBACK
	THROW 
END CATCH

SET NOEXEC OFF