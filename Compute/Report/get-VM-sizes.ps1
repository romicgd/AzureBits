get-Azurermvm  | select @{N='vmSize';E={$_.HardwareProfile.VMsize}}, 
@{N='OS'; E={$_.storageProfile.OSDisk.OSType}} | group -property vmsize, OS | select count, name | sort name
