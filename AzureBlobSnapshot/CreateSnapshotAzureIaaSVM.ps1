<#
.SYNOPSIS
  The below script will take a snapshot of OS Disk and Data Disk for all the VMs with a specific TagName & TagValue
.DESCRIPTION
  Blob Snapshot opearations are performed to all the Azure Virtual Machine with TagName as "Environment" and TagValue as "Production"
.INPUTS
  Needs Credentials for logging to Azure Environment if deployed in On-Prem.
.NOTES
  Version:        1.0
  Author:         Raghuram Korukonda
  Creation Date:  23rd Dec, 2016
  Purpose/Change: Creating Azure Snapshots for Azure IaaS VMs
  
#>
Login-AzureRmAccount -Credential $psCred –SubscriptionId $SubscriptionId -ErrorAction Stop | out-null
Get-AzureRmSubscription -SubscriptionId $SubscriptionId | Select-AzureRmSubscription

$tagResList = Find-AzureRmResource -TagName Environment -TagValue Production

#$tagRsList[0].ResourceId.Split("//")
#subscriptions
#<SubscriptionId>
#resourceGroups
#<ResourceGroupName>
#providers
#Microsoft.Compute
#virtualMachines
#<vmName>

foreach($tagRes in $tagResList) { 
		if($tagRes.ResourceId -like "Microsoft.Compute")
		{
			$vmInfo = Get-AzureRmVM -ResourceGroupName $tagRes.ResourceId.Split("//")[4] -Name $tagRes.ResourceId.Split("//")[8]

				#Condition with no data disks only data disk
				$strAccount = ($vmInfo.StorageProfile.OsDisk.Vhd.Uri).Split('//')[2].Split('/.')[0]
				#Finding the OS Disk resource Group
				$storageDetails = Find-AzureRmResource -ResourceNameContains $strAccount

				$AzStrAct = Get-AzureRmStorageAccount -Name $strAccount -ResourceGroupName $storageDetails.ResourceGroupName
				$AzStrKey = Get-AzureRmStorageAccountKey -Name $strAccount -ResourceGroupName $storageDetails.ResourceGroupName
				$AzStrCtx = New-AzureStorageContext $strAccount -StorageAccountKey $AzStrKey[0].Value 
				$Container = ($vmInfo.StorageProfile.OsDisk.Vhd.Uri).Split('//')[3] 
				$VHDName = ($vmInfo.StorageProfile.OsDisk.Vhd.Uri).Split('//')[4]
				$VHDNameShort = ($vmInfo.StorageProfile.OsDisk.Vhd.Uri).Split('//')[4].Split('/.')[0]
				#$VMName = $vmInfo.Name
				#Finds the OS Disk with VHD Name and Container
				$VMblob = Get-AzureRmStorageAccount -Name $strAccount -ResourceGroupName $storageDetails.ResourceGroupName | Get-AzureStorageContainer | where {$_.Name -eq $Container} | Get-AzureStorageBlob | where {$_.Name -eq $VHDName -and $_.ICloudBlob.IsSnapshot -ne $true}
				#Blob Snapshot
				$VMsnap = $VMblob.ICloudBlob.CreateSnapshot()

				$blob = Get-AzureStorageContainer -Context $AzStrCtx -Name $Container
				$ListOfBlobs = $blob.CloudBlobContainer.ListBlobs($VHDName, $true, "Snapshots")


				if($vmInfo.DataDiskNames.Count -ge 1){
						#Condition with more than one data disks
						for($i=1; $i -le $vmInfo.DataDiskNames.Count; $i++){
								$StrdataDisk = ($vmInfo.StorageProfile.DataDisks[$i].Vhd.Uri).Split('//')[2].Split('/.')[0]
								$storageDetailsdd = Find-AzureRmResource -ResourceNameContains $StrdataDisk

								$AzStrActdd = Get-AzureRmStorageAccount -Name $StrdataDisk -ResourceGroupName $storageDetailsdd.ResourceGroupName
								$AzStrKeydd = Get-AzureRmStorageAccountKey -Name $StrdataDisk -ResourceGroupName $storageDetailsdd.ResourceGroupName
								$AzStrCtxdd = New-AzureStorageContext $StrdataDisk -StorageAccountKey $AzStrKeydd[0].Value 
								$ddContainer = ($vmInfo.StorageProfile.DataDisks[$i].Vhd.Uri).Split('//')[3] 
								$ddVHDName = ($vmInfo.StorageProfile.DataDisks[$i].Vhd.Uri).Split('//')[4]
								$ddVHDNameShort = ($vmInfo.StorageProfile.DataDisks[$i].Vhd.Uri).Split('//')[4].Split('/.')[0]
								#$VMName = $vmInfo.Name
								#Finds the DD Disk with VHD Name and Container
								$ddVMblob = Get-AzureRmStorageAccount -Name $StrdataDisk -ResourceGroupName $storageDetailsdd.ResourceGroupName | Get-AzureStorageContainer | where {$_.Name -eq $ddContainer} | Get-AzureStorageBlob | where {$_.Name -eq $ddVHDName -and $_.ICloudBlob.IsSnapshot -ne $true}
								#Blob Snapshot
								$ddVMsnap = $ddVMblob.ICloudBlob.CreateSnapshot()

								$ddblob = Get-AzureStorageContainer -Context $AzStrCtxdd -Name $ddContainer
								$ddListOfBlobs = $ddblob.CloudBlobContainer.ListBlobs($ddVHDName, $true, "Snapshots")
							
						}
					}
				else{
						Write-Host $vmInfo.Name + " doesn't have any additional data disk."
				}
		}
		else{
		$tagRes.ResourceId + "is not a compute instance"
		}
}

#$tagRgList = Find-AzureRmResourceGroup -Tag @{ Environment = "Production" }