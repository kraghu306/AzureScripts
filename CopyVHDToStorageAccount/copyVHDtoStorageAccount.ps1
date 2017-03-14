#######################################################

 $subscriptionId = ""
 $resourceGroupName = ""
 $SourcelabName = ""
 $listOflabsName = ""
 $sourceUri = ""
 
 $lab = Get-AzureRmResource -ResourceId ('/subscriptions/' + $subscriptionId + '/resourceGroups/' + $resourceGroupName + '/providers/Microsoft.DevTestLab/labs/' + $SourcelabName)

 $storageAccountName = ($lab.Properties.defaultStorageAccount).Split("/")[8]
 $storageDetails = Find-AzureRmResource -ResourceNameContains $storageAccountName
 $AzStrAct = Get-AzureRmStorageAccount -Name $storageAccountName -ResourceGroupName $storageDetails.ResourceGroupName
 $AzStrKey = Get-AzureRmStorageAccountKey -Name $storageAccountName -ResourceGroupName $storageDetails.ResourceGroupName
 #source Storage Account Context
 $SrcAzStrCtx = New-AzureStorageContext $storageAccountName -StorageAccountKey $AzStrKey[0].Value

 $listlabs = $listOflabsName.Split(",")
 foreach($listlab in $listlabs){
  $findlab = Find-AzureRmResource -ResourceNameContains $listlab
  $findlab = Find-AzureRmResource| Where{($_.ResourceName -eq 'dev-lab-south') -and ($_.ResourceType -eq "Microsoft.DevTestLab/labs")}
  $eachlab = Get-AzureRmResource -ResourceId ('/subscriptions/' + $subscriptionId + '/resourceGroups/' + $findlab.ResourceGroupName + '/providers/Microsoft.DevTestLab/labs/' + $findlab.Name)
  $storageAccName = ($findlab.Properties.defaultStorageAccount).Split("/")[8]
  $storeDetails = Find-AzureRmResource -ResourceNameContains $storageAccName
  $DesAzStrAct = Get-AzureRmStorageAccount -Name $storageAccName -ResourceGroupName $storeDetails.ResourceGroupName
  $DesAzStrKey = Get-AzureRmStorageAccountKey -Name $storageAccName -ResourceGroupName $storeDetails.ResourceGroupName
  $DesAzStrCtx = New-AzureStorageContext $storageAccName -StorageAccountKey $DesAzStrKey[0].Value
  $containerName = "mastervhds"
  
  #$sourceUri = https://ddevlabsouth1716.blob.core.windows.net/vhds/dev-lab-south241587640000-devlab1-20170312-145712.vhd 
  
  $vhdFileName = $sourceUri.Split("/")[4]
  
  $copyHandle = Start-AzureStorageBlobCopy -srcUri $sourceUri -SrcContext $SrcAzStrCtx -DestContainer 'copyvhd' -DestBlob $vhdFileName -DestContext $DesAzStrCtx -Force

  Write-Host "Copy started..."

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
  #/subscriptions/affcde79-682a-4e26-84a6-9c5969ae240f/resourcegroups/ptc-devtest-1/providers/microsoft.devtestlab/labs/dev-lab-south/customimages/img-win10vs2017
 }