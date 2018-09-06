<#
.SYNOPSIS 
    Copy VM managed Disks another subscription.

.DESCRIPTION
    . 

.PARAMETER SourceSubscriptionName
    Subscription where backup VMs and the a Recovery Services Vault is located

.PARAMETER SourceVMResourceGroup    
    Name of a Recovery Services Vault

.PARAMETER TargetSubscriptionName    
    Name of Resource Group that contains VMs

.PARAMETER TargetVMResourceGroup    
    Name of backup policy (optional)

.EXAMPLE
    .operations\Compute\Copy-VMManagedDisks.ps1  -SourceSubscriptionName "itsdev01pcf" -SourceVMResourceGroup "testrg" `
    -TargetSubscriptionName "0013tbsdev08wrk" -TargetVMResourceGroup "tbs-dev-08-cc-0013-e0013-rgp-w8gs" `
    -TargetVnetResourceGroup "tbs-dev-08-cc-0013-e0013-rgp-w8gs" -TargetVnetName "testvnet" -TargetSubnetName "default"
 
#>

Param (
    [Parameter(Mandatory=$true, Position=1)]
    [string]$SourceSubscriptionName,

    [Parameter(Mandatory=$true, Position=2)]
    [string]$SourceVMResourceGroup,

    [Parameter(Mandatory=$true, Position=3)]
    [string]$TargetSubscriptionName,

    [Parameter(Mandatory=$true, Position=4)]
    [string]$TargetVMResourceGroup,

    [Parameter(Mandatory=$true, Position=5)]
    [string]$TargetVnetResourceGroup,

    [Parameter(Mandatory=$true, Position=6)]
    [string]$TargetVnetName,

    [Parameter(Mandatory=$true, Position=7)]
    [string]$TargetSubnetName,

    [Parameter(Mandatory=$false, Position=8)]
    [string]$Location="canadacentral"
    )

#Import Module
Import-Module "$PSScriptRoot\..\..\ITSAzure.psd1" -Force

Connect-ITSAz

Set-AzureRmContext -SubscriptionName $SourceSubscriptionName

$vms =  Get-AzureRMVM -resourcegroup $SourceVMResourceGroup

foreach($vm in $VMs) {
    #Set the context to the subscription Id where Managed Disk exists
    Set-AzureRmContext -SubscriptionName $SourceSubscriptionName

    if (!$vm.StorageProfile.OsDisk.ManagedDisk)
    {   
        throw "The VM has Unmanaged OS Disk."    
    }    

    Write-ITSAzLog -Message "Getting VM Status..."
    # Get current status of the VM
    $vmstatus = Get-AzureRmVM -ResourceGroupName $SourceVMResourceGroup -Name $VM.Name -Status

    Write-Verbose "Checking if VM is in a Running State..."
    If ($vmstatus.Statuses.Code -contains "PowerState/running")
    {
        Write-ITSAzLog -Message  "Stopping the VM as it is in a Running State..."
        $stopVM = Stop-AzureRmVM -ResourceGroupName $SourceVMResourceGroup -Name $VM.Name -Force
    }

    #Get the source managed disk
    $vmOSDisk = Get-AzureRmDisk -ResourceGroupName $SourceVMResourceGroup -DiskName $vm.StorageProfile.OSDisk.Name

    $vmDataDisks = @{}
    foreach($vmdatadisk in $vm.StorageProfile.DataDisks) {
        $DataDisk = Get-AzureRmDisk -ResourceGroupName $SourceVMResourceGroup -DiskName $vmdatadisk.name
        $vmDataDisks.add($vmdatadisk.Lun, $DataDisk)
    }

    #Set the context to the subscription Id where Managed Disk exists
    Set-AzureRmContext -SubscriptionName $TargetSubscriptionName

    $OSdiskConfig = New-AzureRmDiskConfig -SourceResourceId $vmOSDisk.Id -Location $vmOSDisk.Location -CreateOption Copy 

    #Create a new managed disk in the target subscription and resource group
    $newOSDisk=New-AzureRmDisk -Disk $OSdiskConfig -DiskName $vm.StorageProfile.OSDisk.Name -ResourceGroupName $TargetVMResourceGroup

    $NewVirtualMachine = New-AzureRmVMConfig -VMName $VM.Name -VMSize $vm.HardwareProfile.VmSize

    $NewVirtualMachine = Set-AzureRmVMOSDisk -VM $NewVirtualMachine -ManagedDiskId $newOSDisk.Id -CreateOption Attach -Linux

    $vmNewDataDisks = @()
    foreach($datadiskLun in $vmDataDisks.keys) {
        $datadisk = $vmDataDisks[$datadiskLun]
        $NewDataDiskConfig = New-AzureRmDiskConfig -SourceResourceId $datadisk.Id -Location $Location -CreateOption Copy 
        $vmNewDataDisk=New-AzureRmDisk -Disk $NewDataDiskConfig -DiskName $datadisk.Name -ResourceGroupName $TargetVMResourceGroup
        $vmNewDataDisks+=($vmNewDataDisk)
        Add-AzureRmVMDataDisk -VM $NewVirtualMachine -Lun $datadiskLun -ManagedDiskId $vmNewDataDisk.Id -CreateOption Attach 
    }

    $vnet = Get-AzureRmVirtualNetwork -Name $TargetVnetName -ResourceGroupName $TargetVnetResourceGroup
    $subnet = Get-AzureRmVirtualNetworkSubnetConfig -Name $TargetSubnetName -VirtualNetwork $vnet 

    # Create NIC 
    $nic = New-AzureRmNetworkInterface -Name ($VM.Name.ToLower()+'_nic001') -ResourceGroupName $TargetVMResourceGroup -Location $Location -SubnetId $Subnet.Id 

    $NewVirtualMachine = Add-AzureRmVMNetworkInterface -VM $NewVirtualMachine -Id $nic.Id

    New-AzureRmVM -VM $NewVirtualMachine -ResourceGroupName $TargetVMResourceGroup -Location $Location
}

