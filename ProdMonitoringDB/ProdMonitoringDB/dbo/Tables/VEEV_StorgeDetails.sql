Create table VEEV_StorgeDetails
(
StorgeDetailsId uniqueidentifier not null primary key,
DataStorageMaxMB int not null,
DataStorageRemainingMB int not null,
FileStorageMaxMB int not null,
FileStorageRemainingMB int not null,
StartDate datetime,
EndDate datetime,
UpdatedDate datetime,
CustomerId int  not null
)