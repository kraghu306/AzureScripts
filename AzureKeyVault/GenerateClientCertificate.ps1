param(
[parameter(Mandatory=$true, ParameterSetName="GenerateCertificate")]
[string]$Subject,

[parameter(Mandatory=$false, ParameterSetName="GenerateCertificate")]
[string]$CertStoreLocation = "Cert:\CurrentUser\My",

[parameter(Mandatory=$false, ParameterSetName="GenerateCertificate")]
[DateTime]$NotBefore = [DateTime]::Now.Date,

[parameter(Mandatory=$false, ParameterSetName="GenerateCertificate")]
[DateTime]$NotAfter = $NotBefore.AddYears(1),

[parameter(Mandatory=$false, ParameterSetName="GenerateCertificate")]
[ValidateScript({if ($_){ Test-Path $_ -PathType Container }})][string]$OutputPath
)

switch($PSCmdlet.ParameterSetName)
{
    "GenerateCertificate"
        {
            # There is an existing bug with PowerShell where $PSScriptRoot is not set if used as a parameter's default value.  We'll work around
            # this here by checking to see if a value was provided for $OutputPath, and if not, use the default
            if ($PSBoundParameters.ContainsKey('OutputPath'))
            {
                $outputFilePath = Join-Path $OutputPath "$Subject.cer"
            }
            else
            {
                $OutputFilePath = "$PSScriptRoot\$Subject.cer"
            }

            $x509Cert = New-SelfSignedCertificate -NotBefore $NotBefore -NotAfter $NotAfter -Subject $Subject -CertStoreLocation $CertStoreLocation -Provider "Microsoft Strong Cryptographic Provider"

            # Export the public key portion of the certificate
            $cerFileInfo = Export-Certificate -Cert $x509Cert -FilePath $outputFilePath
            $publicKeyCert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
            $publicKeyCert.Import($outputFilePath)

            $rawCertData = [System.Convert]::ToBase64String($publicKeyCert.GetRawCertData())
            $thumbprint = [System.Convert]::ToBase64String($publicKeyCert.GetCertHash())
            $keyId = [System.Guid]::NewGuid().ToString()

            $jsonForManifest = "{ `"type`": `"AsymmetricX509Cert`", `"usage`": `"Verify`", `"keyId`": `"$keyId`", `"customKeyIdentifier`": `"$thumbprint`", `"value`" : `"$rawCertData`" }"
            $($jsonForManifest)
        }
}