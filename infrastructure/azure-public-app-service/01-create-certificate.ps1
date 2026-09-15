$ErrorActionPreference = 'Stop'

# ==============================================================================
# User-configurable settings
# ==============================================================================

$CertificateName = 'DEV:14053:MetIQ:Automation:AppDeploy'
$CertificateFileName = $CertificateName -replace ':', '-'
$CertificateValidityDays = 3650
$CertificateBaseDirectory = if ([string]::IsNullOrWhiteSpace($PSScriptRoot)) {
    (Get-Location).Path
} else {
    $PSScriptRoot
}
$CertificateOutputDirectory = Join-Path $CertificateBaseDirectory $CertificateFileName
$PfxPassword = ''

# ==============================================================================
# Validation and certificate generation
# ==============================================================================

if ($CertificateValidityDays -le 0) {
    throw '[ERROR] CertificateValidityDays must be a positive integer.'
}

if (Test-Path -LiteralPath $CertificateOutputDirectory) {
    throw "[ERROR] Certificate output path already exists: $CertificateOutputDirectory"
}

New-Item -ItemType Directory -Path $CertificateOutputDirectory | Out-Null

$pfxFile = Join-Path $CertificateOutputDirectory "$CertificateFileName.pfx"
$cerFile = Join-Path $CertificateOutputDirectory "$CertificateFileName.cer"
$pemFile = Join-Path $CertificateOutputDirectory "$CertificateFileName.cert.pem"
$certificate = $null

try {
    $certificate = New-SelfSignedCertificate `
        -Type Custom `
        -Subject "CN=$CertificateName" `
        -KeyAlgorithm RSA `
        -KeyLength 4096 `
        -HashAlgorithm SHA256 `
        -KeyExportPolicy Exportable `
        -KeySpec Signature `
        -NotAfter (Get-Date).AddDays($CertificateValidityDays) `
        -TextExtension @('2.5.29.37={text}1.3.6.1.5.5.7.3.2') `
        -CertStoreLocation 'Cert:\CurrentUser\My'

    if (-not [string]::IsNullOrEmpty($PfxPassword)) {
        $securePfxPassword = ConvertTo-SecureString $PfxPassword -AsPlainText -Force
        Export-PfxCertificate `
            -Cert $certificate `
            -FilePath $pfxFile `
            -Password $securePfxPassword | Out-Null
    } else {
        $pfxBytes = $certificate.Export(
            [System.Security.Cryptography.X509Certificates.X509ContentType]::Pfx
        )
        [System.IO.File]::WriteAllBytes($pfxFile, $pfxBytes)
    }

    Export-Certificate `
        -Cert $certificate `
        -FilePath $cerFile `
        -Type CERT | Out-Null

    $pemBody = [Convert]::ToBase64String($certificate.RawData)
    $pemLines = [regex]::Matches($pemBody, '.{1,64}') | ForEach-Object { $_.Value }
    @('-----BEGIN CERTIFICATE-----') + $pemLines + @('-----END CERTIFICATE-----') |
        Set-Content -Path $pemFile -Encoding ASCII

    Write-Host '[SUCCESS] Certificate created'
    Write-Host "[INFO] PEM certificate :: $pemFile"
    Write-Host "[INFO] CER certificate :: $cerFile"
    Write-Host "[INFO] PFX certificate :: $pfxFile"
    Write-Host "[INFO] Validity :: $CertificateValidityDays days"

    if (-not [string]::IsNullOrEmpty($PfxPassword)) {
        $passwordFile = Join-Path $CertificateOutputDirectory "$CertificateFileName.password.txt"
        Set-Content -Path $passwordFile -Value $PfxPassword -NoNewline -Encoding ASCII
        Write-Host "[INFO] PFX password file :: $passwordFile"
    }
}
finally {
    if ($certificate) {
        Remove-Item -Path "Cert:\CurrentUser\My\$($certificate.Thumbprint)" -Force -ErrorAction SilentlyContinue
    }
}
