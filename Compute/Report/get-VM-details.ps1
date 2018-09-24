foreach ($vm in $vmsizearr) {
    $vmsize=Get-AzureRmVMSize -resourcegroupname $vm.resourcegroupname -vmname $vm.name | where-object {$_.name -eq $($vm.HardwareProfile.VMsize)} 
    $nics = Get-AzureRmNetworkInterface 
    $vmIPs = @()
    Foreach($nic in $nics)  {
        if($vm.Id -eq $nic.virtualmachine.id) {
            $vmIP = $( Get-AzureRmNetworkInterfaceIpConfig -NetworkInterface $nic | Select PrivateIPAddress) 
            $vmIPs += $vmIp.PrivateIPaddress
        }
    }
    $vmIPStr=$vmIPs -join ','    
    "$($vm.name) - $($vm.HardwareProfile.VMsize): CPU[$($vmsize.NumberOfCores)], RAM[$($vmsize.MemoryInMB/1024)], Disk[$($vmsize.OSDiskSizeInMB/1024)], IP[$vmIPStr]" 
}  
