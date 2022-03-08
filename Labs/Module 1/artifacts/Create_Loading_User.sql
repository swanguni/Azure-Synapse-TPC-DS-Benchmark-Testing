

--USE [DedicatedPoolName]
CREATE USER LoadingUser FOR LOGIN LoadingUser; 
GO 

EXEC sp_addrolemember 'db_owner', 'LoadingUser';
GO

-- EXEC sp_addrolemember 'staticrc80', LoadingUser
-- GO

CREATE WORKLOAD GROUP DataLoads
WITH 
( 
   MIN_PERCENTAGE_RESOURCE = 100
   ,CAP_PERCENTAGE_RESOURCE = 100
   ,REQUEST_MIN_RESOURCE_GRANT_PERCENT = 100
)
;

CREATE WORKLOAD CLASSIFIER [wgcELTLogin]
WITH 
(
	 WORKLOAD_GROUP = 'DataLoads'
   ,MEMBERNAME = 'LoadingUser'
)
;
