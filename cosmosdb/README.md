# Script and utilities to support CosmosDB DevOps

## Note:
Depends on CosmosDB PowerShell Module
https://www.powershellgallery.com/packages/CosmosDB/2.0.14.439


### listCosmosDbDetails.ps1 
Collect and report information on CosmosDB accounts, databaes, collections and sizes in the current subscription

#### Sample output

```
Accounts:

Name                       DefaultExperience consistencyPolicy                                                                   databaseAccountOfferType
----                       ----------------- -----------------                                                                   ------------------------
cosmosaccount1xxxxxxxxxxxx                    @{defaultConsistencyLevel=Eventual; maxIntervalInSeconds=5; maxStalenessPrefix=100} Standard                
cosmosaccount2xxxxxxxxxxxx                    @{defaultConsistencyLevel=Eventual; maxIntervalInSeconds=5; maxStalenessPrefix=100} Standard                
cosmosaccount3xxxxxxxxxxxx  Table             @{defaultConsistencyLevel=BoundedStaleness; maxIntervalInSeconds=86400; maxStale... Standard                
cosmosaccount4xxxxxxxxxxxx  Graph             @{defaultConsistencyLevel=Session; maxIntervalInSeconds=5; maxStalenessPrefix=100}  Standard                

Details:
Account [cosmosaccount1xxxxxxxxxxxx]
Database [acc1db1]
Collection [items] PartitionKey[]

Name                           Value                                                                                                                                                                               
----                           -----                                                                                                                                                                               
triggers                       2                                                                                                                                                                                   
collectionSize                 3612                                                                                                                                                                                
documentsCount                 1581                                                                                                                                                                                
functions                      0                                                                                                                                                                                   
storedProcedures               6                                                                                                                                                                                   
documentsSize                  3196                                                                                                                                                                                
documentSize                   3                                                                                                                                                                                   



Account [cosmosaccount2xxxxxxxxxxxx]
Database [acc2db1]
Collection [fancycollection] PartitionKey[/'$pk']

Name                           Value                                                                                                                                                                               
----                           -----                                                                                                                                                                               
triggers                       0                                                                                                                                                                                   
collectionSize                 441                                                                                                                                                                                 
documentsCount                 62                                                                                                                                                                                  
functions                      0                                                                                                                                                                                   
storedProcedures               2                                                                                                                                                                                   
documentsSize                  425                                                                                                                                                                                 
documentSize                   0                                                                                                                                                                                   

```
