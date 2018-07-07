<#
 Depends on:
    Module -Name CosmosDB 

    Install-Module -Name CosmosDB -RequiredVersion 2.0.12.418

 References: 
    ttps://docs.microsoft.com/en-us/azure/active-directory/active-directory-identityprotection-graph-getting-started
    https://docs.microsoft.com/en-us/azure/active-directory/active-directory-reporting-risk-events 
 #>

# MS Graph Authentication
$tenantdomain   = ""   # For example, contoso.onmicrosoft.com
$loginURL       = "https://login.microsoft.com"
$resource       = "https://graph.microsoft.com"
$keyVaultName   = ""
$clientIdName = ""
$clientSecretName = ""

# Login to Azure
$Conn = Get-AutomationConnection -Name AzureRunAsConnection
Add-AzureRMAccount -ServicePrincipal -Tenant $Conn.TenantID -ApplicationId $Conn.ApplicationID -CertificateThumbprint $Conn.CertificateThumbprint

# Get Auth Token
$ClientId = (Get-AzureKeyVaultSecret –VaultName $keyVaultName -Name $clientIdName).SecretValueText
$ClientSecret = (Get-AzureKeyVaultSecret –VaultName $keyVaultName -Name $clientSecretName).SecretValueText
Write-Output "Graph reader SPN credentials retrieved."
$body      = @{grant_type="client_credentials";resource=$resource;client_id=$ClientID;client_secret=$ClientSecret}
$oauth     = Invoke-RestMethod -Method Post -Uri $loginURL/$tenantdomain/oauth2/token?api-version=1.0 -Body $body
Write-Output $oauth


# get leaked credentials events
if ($oauth.access_token -ne $null) {
   $headerParams = @{'Authorization'="$($oauth.token_type) $($oauth.access_token)"}
#  $url = "https://graph.microsoft.com/beta/identityRiskEvents"
#  $url = "https://graph.microsoft.com/beta/users?`$filter=startswith(displayName,'T')"
  $url = "https://graph.microsoft.com/beta/leakedCredentialsRiskEvents"
   Write-Output $url
   $myReport = ""
   $myReport = (Invoke-WebRequest -UseBasicParsing  -Headers $headerParams -Uri $url)
   $leakedCredentials = @()
   foreach ($event in (($myReport.Content | ConvertFrom-Json).value)) {
       $event | Add-Member DataLoadTime ([datetime]::Now.ToString('yyyy-MM-ddTHH:mm:ss'))
       $leakedCredentials += $event  
   }
   $leakedCredentials 
} else {
   Write-Output "ERROR: No Access Token"
}

# init cosmosdb
$cosmosdbAccount=""
$cosmosDbDatabase=""
$cosmosdbCollectionId = ""
$PrdInfCosmosDbMasterKeyName = ""
$PrdInfCosmosDbMasterKey = (Get-AzureKeyVaultSecret –VaultName $keyVaultName -Name $PrdInfCosmosDbMasterKeyName).SecretValueText

Write-Output "Initialize CosmosDB "
$primaryKey = ConvertTo-SecureString -String $PrdInfCosmosDbMasterKey -AsPlainText -Force
$cosmosDbContext = New-CosmosDbContext -Account $cosmosdbAccount -Database $cosmosDbDatabase -Key $primaryKey
Remove-CosmosDbCollection -Context $cosmosDbContext -Id $cosmosdbCollectionId
New-CosmosDbCollection -Context $cosmosDbContext -Id $cosmosdbCollectionId -OfferThroughput 1000
Write-Output "CosmosDB Initialized"

# initialize exceptions
$exceptions = @()

# load active leakedCredentials accounts
foreach ($event in $leakedCredentials)  {
    if($($event.riskEventStatus) -eq 'active') {
        try {
            $eventjson = $event | ConvertTo-Json
            New-CosmosDbDocument -Context $cosmosDbContext -CollectionId $cosmosdbCollectionId -DocumentBody $eventjson 
        } catch {
            $status = $_.Exception.Response.StatusCode 
            if ($status -eq 'Conflict') {
                Write-Output "Found Existing id[$($event.id)] " -erroraction continue
                Set-CosmosDbDocument -Context $cosmosDbContext -CollectionId $cosmosdbCollectionId -Id $event.id -DocumentBody $eventjson 
            } else {
               $exceptions += "Error $($_.Exception.Message) id[$($event.id)]"
            }
       }
    }
} 

# report errors
foreach($exception in $exceptions) {
    Write-Error $exception
}
