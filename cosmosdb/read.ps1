$cosmosdbAccount=""
$cosmosDbDatabase=""
$cosmosdbCollectionId = ""

$primaryKey = ConvertTo-SecureString -String "" -AsPlainText -Force
$cosmosDbContext = New-CosmosDbContext -Account $cosmosdbAccount -Database $cosmosDbDatabase -Key $primaryKey
Get-CosmosDbDocument -Context $cosmosDbContext -CollectionId $cosmosdbCollectionId