workflow Copy-VHD-StorageAccounts
{
    #The name of the Automation Credential Asset this runbook will use to authenticate to Azure.
    $CredentialAssetName = 'DefaultAzureCredential'

    #Get the credential with the above name from the Automation Asset store
    $Cred = Get-AutomationPSCredential -Name $CredentialAssetName
    if(!$Cred) {
        Throw "Could not find an Automation Credential Asset named '${CredentialAssetName}'. Make sure you have created one in this Automation Account."
    }

    #Connect to your Azure Account
    $Account = Add-AzureRmAccount -Credential $Cred
    $sub = Select-AzureRmSubscription -Name 'Enterprise Dev/Test'
    $subscriptionId = $sub.Subscription.SubscriptionId
    if(!$Account) {
        Throw "Could not authenticate to Azure using the credential asset '${CredentialAssetName}'. Make sure the user name and password are correct."
    }

	 $resourceGroupName = "ptc-poc-central"
	 $SourcelabName = "devtest-1"
	 $listOflabsName = "devtest-2,devtest-3"
	 
	 $lab = Get-AzureRmResource -ResourceId ('/subscriptions/' + $subscriptionId + '/resourceGroups/' + $resourceGroupName + '/providers/Microsoft.DevTestLab/labs/' + $SourcelabName)

	 $storageAccountName = ($lab.Properties.defaultStorageAccount).Split("/")[8]
	 $storageDetails = Find-AzureRmResource -ResourceNameContains $storageAccountName
	 $AzStrAct = Get-AzureRmStorageAccount -Name $storageAccountName -ResourceGroupName $storageDetails.ResourceGroupName
	 $AzStrKey = Get-AzureRmStorageAccountKey -Name $storageAccountName -ResourceGroupName $storageDetails.ResourceGroupName
	 #source Storage Account Context
	 $SrcAzStrCtx = New-AzureStorageContext $storageAccountName -StorageAccountKey $AzStrKey[0].Value
	 
	 $sourceVhdName = (Get-AzureRmStorageAccount -Name $labStorageAccountName -ResourceGroupName $labStorageAccount.ResourceGroupName | Get-AzureStorageContainer | where {$_.Name -eq 'mastervhds'} | Get-AzureStorageBlob).Name

	 $listlabs = $listOflabsName.Split(",")
	 
	 #foreach with multiple storage accounts
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
	  
	  $sourcevhdUri = 'https://'+ $storageAccountName + '.blob.core.windows.net/vhds/'+ $sourceVhdName
	  
	  #$sourceUri = https://ddevlabsouth1716.blob.core.windows.net/vhds/dev-lab-south241587640000-devlab1-20170312-145712.vhd 
	  
	  $vhdFileName = $sourceUri.Split("/")[4]
	  
	  $copyHandle = Start-AzureStorageBlobCopy -srcUri $sourcevhdUri -SrcContext $SrcAzStrCtx -DestContainer 'customvhds' -DestBlob $vhdFileName -DestContext $DesAzStrCtx -Force

	  Write-Host "Copy started..."

	   $BlobCpyAry +=$copyHandle
	 #/subscriptions/affcde79-682a-4e26-84a6-9c5969ae240f/resourcegroups/ptc-devtest-1/providers/microsoft.devtestlab/labs/dev-lab-south/customimages/img-win10vs2017
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
}
