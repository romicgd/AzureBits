<#
   .SYNOPSIS
       Set access token lifetime fro web app
       based on  https://docs.microsoft.com/en-us/azure/active-directory/active-directory-configurable-token-lifetimes 
       
       Depends on: https://www.powershellgallery.com/packages/AzureADPreview/2.0.0.114

   .EXAMPLE
        e.g. set lifetime to 10min
    
#>

New-AzureADPolicy -Definition @('{"TokenLifetimePolicy":{"Version":1,"AccessTokenLifetime":"00:10:00","MaxAgeSessionSingleFactor":"00:10:00"}}') -DisplayName "WebPolicyScenario" -IsOrganizationDefault $false -Type "TokenLifetimePolicy"
Add-AzureADServicePrincipalPolicy -Id "ServicePrincipalId" -RefObjectId "PolicyId"