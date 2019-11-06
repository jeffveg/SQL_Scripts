


		 OPEN SYMMETRIC KEY SymmetricKey 
	DECRYPTION BY CERTIFICATE EncryptCert 



	SELECT     top 10
			   CONVERT(VARCHAR(500), DECRYPTBYKEY(AuthCodes.AuthCode_Name)) as AuthCode, 
			   CONVERT(VARCHAR(500), DECRYPTBYKEY(CreditDetails.OrderCreditCard_ExpiryDate)) as ExiryDate,
			   CONVERT(VARCHAR(500), DECRYPTBYKEY(CreditDetails.OrderCreditCard_Type)) as CardType
	FROM         
			   AuthCode_OrderProduct RIGHT OUTER JOIN
               AuthCode_Order INNER JOIN
               Order_CreditCardDetails AS CreditDetails INNER JOIN
               Orders ON CreditDetails.OrderCreditCard_OrderID = Orders.Order_ID ON 
               AuthCode_Order.AuthCodeOrder_OrderID = Orders.Order_ID RIGHT OUTER JOIN
               AuthCodes ON AuthCode_Order.AuthCodeOrder_AuthCodeID = AuthCodes.AuthCode_ID ON 
               AuthCode_OrderProduct.AuthCodeOrderProd_AuthCodeID = AuthCodes.AuthCode_ID
where CONVERT(VARCHAR(500), DECRYPTBYKEY(AuthCodes.AuthCode_Name)) is not null

/*
	SELECT 
	FROM
		AuthCodes
	LEFT OUTER JOIN
		AuthCode_OrderProduct ON AuthCode_OrderProduct.AuthCodeOrderProd_AuthCodeID = AuthCodes.AuthCode_ID
	LEFT OUTER JOIN	
		AuthCode_Order ON AuthCode_Order.AuthCodeOrder_AuthCodeID = AuthCodes.AuthCode_ID
	INNER JOIN 
		OrderProducts ON OrderProducts.Prod_ID = AuthCode_OrderProduct.AuthCodeOrderProd_OrderProdID
	INNER JOIN
		Order_CreditCardDetails CreditDetails ON CreditDetails.OrderCreditCard_OrderID = AuthCode_Order.AuthCodeOrder_OrderID OR 
												 CreditDetails.OrderCreditCard_OrderID = OrderProducts.Prod_OrderID

*/

	CLOSE SYMMETRIC KEY SymmetricKey



Use ICE_US_TB
go

alter master key add encryption by password = 'P@55w)rd!'
go 
backup master key to file = N'c:\ICE_US_TB_DB_KeyBackup'
	encryption by password = 'P@55w)rd!'


	DECLARE @DBName NVARCHAR(255)
	,@BackUpPath NVARCHAR(255)

/* Set DB and Path here */
SET @DBName = N'ICE_US_TB'
SET @BackUpPath = N'c:\'

/*********************************************************************/
/*make sure there is a \ at the end of the path  */
IF substring(@BackupPath, len(@BackupPath), 1) <> '\'
	SET @BackupPath = @BackupPath + '\'

DECLARE @CRLF NCHAR(2)
	,@SQL NVARCHAR(4000)

SET @CRLF = CHAR(13) + CHAR(10)
SET @SQL = 'BACKUP DATABASE [' + @DBName + ']' + @CRLF
SET @SQL = @SQL + '  TO DISK = ''' + @BackUpPath + @DBName + '.bak''' + @CRLF
SET @SQL = @SQL + 'WITH ' + @CRLF
SET @SQL = @SQL + '  NOFORMAT ' + @CRLF
SET @SQL = @SQL + ' ,NAME = N''' + @DBName + '-Full Database Backup''' + @CRLF
SET @SQL = @SQL + ' ,SKIP' + @CRLF

/* Compression is not avaaiable in normal SQL server until 2008 */
IF CAST(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(2)) AS DECIMAL) >= 10
	SET @SQL = @SQL + ' ,COMPRESSION' + @CRLF
SET @SQL = @SQL + ' ,STATS = 10;' + @CRLF

PRINT @SQL + @CRLF

EXEC sp_executeSQL @SQL
