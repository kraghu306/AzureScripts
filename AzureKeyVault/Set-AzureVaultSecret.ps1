param(
[parameter(Mandatory=$true, ParameterSetName="SetConfigValue")]
[string]$KeyVaultName,

[parameter(Mandatory=$false, ParameterSetName="SetConfigValue")]
[string]$KeyName,

[parameter(Mandatory=$false, ParameterSetName="SetConfigValue")]
[string]$KeyValue,

[parameter(Mandatory=$false, ParameterSetName="SetConfigValue")]
[string]$ConfigName
)

function Validate-ValueParameter {
param(
[parameter(Mandatory=$true, ValueFromPipeline=$true)]$ConfigValue
)
    $isValid = $true
    $member = Get-Member -InputObject $ConfigValue -Name "Name"
    if ($member -eq $null)
    {
        throw "Configuration parameter has a missing 'Name' member"
    }

    $member = Get-Member -InputObject $ConfigValue -Name "Value"
    if ($member -eq $null)
    {
        throw "Configuration parameter has a missing 'Value' member"
    }

    $member = Get-Member -InputObject $ConfigValue -Name "Tags"
    if ($member -eq $null)
    {
        throw "Configuration parameter has a missing 'Tags' member"
    }
}

function Set-KeyVaultSecret {
param(
[parameter(Mandatory=$true, ValueFromPipeline=$true)]$ConfigValue
)
    process {
        $secureString = ConvertTo-SecureString -String $ConfigValue.Value -AsPlainText -Force
        Set-AzureKeyVaultSecret -VaultName $KeyVaultName -Name $ConfigValue.Name -SecretValue $secureString -Tags $ConfigValue.Tags
    }
}

switch($PSCmdlet.ParameterSetName)
{
    "SetConfigValue"
        {
            $KeyValueObject = [PSCustomObject]@{ Name=$KeyName; Value=$KeyValue; Tags=@{"ConfigKey"=$ConfigName}}

            #Make sure our $KeyValueObject is valid
            Validate-ValueParameter $KeyValueObject
            #Everything is good, so login to AzureRM
            #Login-AzureRmAccount
            #Setup secrets
            $key = Set-KeyVaultSecret $KeyValueObject
        }
}