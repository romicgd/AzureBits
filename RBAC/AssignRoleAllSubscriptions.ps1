$Role = Get-AzureRmRoleDefinition -Name "Reader" -scope "/"
foreach ($subscription in get-azurermsubscription) {
    if ($subscription.name -match ".*(test|dev|prod)xxx---yyy") {
        $env=$matches[1]
        $nwgroup = Get-AzureRmADGroup -SearchString "MyAdmin-$env-Role"
        Write-output $env
        Write-output $nwgroup
        Add-ITSAzAzureAdminRole $Role "/subscriptions/$($Subscription.Id)" $nwgroup.id
    }
}
