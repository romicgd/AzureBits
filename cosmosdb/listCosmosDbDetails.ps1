$dbaccounts = Get-AzureRmResource -ResourceType "Microsoft.DocumentDB/databaseAccounts"
Write-output "Accounts:"
foreach($cosmosdbAccount in $dbaccounts) {
    $dbaccountProp = Get-AzureRmResource -ResourceType "Microsoft.DocumentDb/databaseAccounts" -ApiVersion "2015-04-08" `
        -ResourceGroupName $cosmosdbAccount.ResourceGroupName -Name $cosmosdbAccount.Name
    $properties = @()
    $properties += @{
    Name = "Name"
    Expression = {$_.Name}
    }
    $properties += @{
        Name = "DefaultExperience"
        Expression = {$_.tags.defaultExperience}
    }
    $properties += @{
        Name = "consistencyPolicy"
        Expression = {$_.properties.consistencyPolicy}
    }
    $properties += @{
        Name = "databaseAccountOfferType"
        Expression = {$_.properties.databaseAccountOfferType}
    }
    $dbaccountProp | Select-Object $properties
    }

Write-output ""
Write-output "Details:"

foreach($cosmosdbAccount in $dbaccounts) {
    $dbaccountProp = Get-AzureRmResource -ResourceType "Microsoft.DocumentDb/databaseAccounts" -ApiVersion "2015-04-08" `
        -ResourceGroupName $cosmosdbAccount.ResourceGroupName -Name $cosmosdbAccount.Name
    Write-Output "Account [$($dbaccountProp.Name)]"
	$keys = Invoke-AzureRmResourceAction -Action listKeys -ResourceType "Microsoft.DocumentDb/databaseAccounts" `
        -ApiVersion "2015-04-08" -ResourceGroupName $cosmosdbAccount.ResourceGroupName -Name $cosmosdbAccount.Name -force
    $primaryKey = ConvertTo-SecureString -String $keys.primaryMasterKey -AsPlainText -Force
    $cosmosDbContext = New-CosmosDbContext -Account $cosmosdbAccount -Key $primaryKey
    $databases = Invoke-AzureRmResourceAction -Action listDatabases -ResourceType "Microsoft.DocumentDb/databaseAccounts" `
        -ApiVersion "2015-04-08"  -ResourceGroupName $cosmosdbAccount.ResourceGroupName  -Name $cosmosdbAccount.Name -force
    foreach($cosmosDbDatabase in $databases.databases) {
        Write-Output "Database [$($cosmosDbDatabase.id)]"
        $cosmosDbContext = New-CosmosDbContext -Account $dbaccountProp.Name -Database $cosmosDbDatabase.id -Key $primaryKey
        $database = Get-CosmosDbDatabase -Context $cosmosDbContext -id $cosmosDbDatabase.id
        $collections =  Get-CosmosDbCollection -Context $cosmosDbContext 
        $offers = Get-CosmosDbOffer -Context $cosmosDbContext
        foreach($cosmosDBcollection in $collections) {
            Write-Output "Collection [$($cosmosDBcollection.id)] PartitionKey[$($cosmosDBcollection.partitionKey.Paths)]"
            if(-not "TablesDB" -match $dbaccountProp.tags.defaultExperience) {
                $collectionSize= Get-CosmosDbCollectionSize -Context $cosmosDbContext -id $cosmosDBcollection.id
                Write-output ($collectionsize | Out-String )
            }
            foreach($offer in $offers) {
                if($off.resource -eq $cosmosDBcollection._self) {
                    Write-output ($off.content | Out-String )
                }
            }        
        }
    }    
}


