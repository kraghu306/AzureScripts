 $scId = "affcde79-682a-4e26-84a6-9c5969ae240f"
 $resourceGroupName = "ptc-poc-central"
 $SourcelabName = "devtest-1"
 $listOflabsName = "devtest-2,devtest-3"
 
 $lab = Get-AzureRmResource -ResourceId ('/subscriptions/' + $scId + '/resourceGroups/' + $resourceGroupName + '/providers/Microsoft.DevTestLab/labs/' + $SourcelabName)

 $storageAccountName = ($lab.Properties.defaultStorageAccount).Split("/")[8]
 $storageDetails = Find-AzureRmResource -ResourceNameContains $storageAccountName
 $AzStrAct = Get-AzureRmStorageAccount -Name $storageAccountName -ResourceGroupName $storageDetails.ResourceGroupName
 $AzStrKey = Get-AzureRmStorageAccountKey -Name $storageAccountName -ResourceGroupName $storageDetails.ResourceGroupName
 #source Storage Account Context
 $SrcAzStrCtx = New-AzureStorageContext $storageAccountName -StorageAccountKey $AzStrKey[0].Value
 
 $sourceVhdName = (Get-AzureRmStorageAccount -Name $labStorageAccountName -ResourceGroupName $labStorageAccount.ResourceGroupName | Get-AzureStorageContainer | where {$_.Name -eq 'vhds'} | Get-AzureStorageBlob).Name

 $listlabs = $listOflabsName.Split(",")
 
 #foreach with multiple storage accounts
 foreach($listlab in $listlabs){
  $findlab = Find-AzureRmResource -ResourceNameContains $listlab
  $findlab = Find-AzureRmResource| Where{($_.ResourceName -eq 'dev-lab-south') -and ($_.ResourceType -eq "Microsoft.DevTestLab/labs")}
  $eachlab = Get-AzureRmResource -ResourceId ('/subscriptions/' + $scId + '/resourceGroups/' + $findlab.ResourceGroupName + '/providers/Microsoft.DevTestLab/labs/' + $findlab.Name)
  $storageAccName = ($findlab.Properties.defaultStorageAccount).Split("/")[8]
  $storeDetails = Find-AzureRmResource -ResourceNameContains $storageAccName
  $DesAzStrAct = Get-AzureRmStorageAccount -Name $storageAccName -ResourceGroupName $storeDetails.ResourceGroupName
  $DesAzStrKey = Get-AzureRmStorageAccountKey -Name $storageAccName -ResourceGroupName $storeDetails.ResourceGroupName
  $DesAzStrCtx = New-AzureStorageContext $storageAccName -StorageAccountKey $DesAzStrKey[0].Value
  $containerName = "mastervhds"
  
  $sourcevhdUri = 'https://'+ $storageAccountName + '.blob.core.windows.net/vhds/'+ $sourceVhdName
  
  $vhdFileName = $sourceUri.Split("/")[4]
  
  $copyHandle = Start-AzureStorageBlobCopy -srcUri $sourcevhdUri -SrcContext $SrcAzStrCtx -DestContainer 'vhds' -DestBlob $vhdFileName -DestContext $DesAzStrCtx -Force

  Write-Host "Copy started..."

   $BlobCpyAry +=$copyHandle
  }

foreach ($BlobCopy in $BlobCpyAry)
{
 	$copyStatus = $copyHandle | Get-AzureStorageBlobCopyState
	While($copyStatus.Status -eq "Pending"){
	$copyStatus = $copyHandle | Get-AzureStorageBlobCopyState 
	$perComplete = ($copyStatus.BytesCopied/$copyStatus.TotalBytes)*100
	Write-Progress -Activity "Copying blob..." -status "Percentage Complete" -percentComplete "$perComplete"
	Start-Sleep 10
	}

	if($copyStatus.Status -eq "Success")
	{
		Write-Host "$vhdFileName successfully copied to Lab $labName "

	}
}
