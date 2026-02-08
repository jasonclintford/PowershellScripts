#!/usr/bin/env pwsh
[CmdletBinding()]
param()

Write-Host "AUTHORIZED USE ONLY - Security script launcher."

$scripts = @(
    "00-ContainerBootstrap.ps1",
    "00-SecretsSetup.ps1",
    "00-LintAndFormat.ps1",
    "10-SubnetReachability.ps1",
    "11-TcpPortCheck.ps1",
    "12-TracerouteBaseline.ps1",
    "13-LocalListeningPorts.ps1",
    "14-NmapWrapperInventory.ps1",
    "20-DnsRecordCollector.ps1",
    "21-SpfDkimDmarcChecker.ps1",
    "22-ReverseDnsSweep.ps1",
    "23-DnsPropagationComparer.ps1",
    "24-DanglingDnsDetector.ps1",
    "30-HttpHeaderBaseline.ps1",
    "31-TlsCertificateAudit.ps1",
    "32-TlsProtocolMatrix.ps1",
    "33-ContentFingerprint.ps1",
    "34-RedirectAndHstsMisconfig.ps1",
    "40-SystemInventory.ps1",
    "41-UserAndSudoAudit.ps1",
    "42-CronAndTimerAudit.ps1",
    "43-WorldWritableAndSuidScan.ps1",
    "44-SSHConfigAudit.ps1",
    "45-FirewallStatusAudit.ps1",
    "50-AuthLogBruteforceDetector.ps1",
    "51-SudoUsageTimeline.ps1",
    "52-JournalctlCollector.ps1",
    "53-WebAccessAnomalyScan.ps1",
    "54-SuspiciousLoginGeoip.ps1",
    "60-DirectoryBaselineHasher.ps1",
    "61-DirectoryChangeDetector.ps1",
    "62-StringIOCScanner.ps1",
    "63-YaraWrapper.ps1",
    "64-ClamavOnDemandScan.ps1",
    "65-SuspiciousFileMetadata.ps1",
    "70-ProcessSnapshot.ps1",
    "71-NetworkProcessCorrelation.ps1",
    "72-LoadedModulesAndKernelParams.ps1",
    "73-PersistenceHunt.ps1",
    "74-ContainerEscapeSurfaceCheck.ps1",
    "80-RemoteCommandFanout.ps1",
    "81-RemoteTriageBundle.ps1",
    "82-RemoteConfigDrift.ps1",
    "83-RemoteFileHashVerifier.ps1",
    "90-PackageVersionCveMatcher.ps1",
    "91-TrivyWrapper.ps1",
    "92-SBOMGenerator.ps1",
    "93-SecretsInRepoScan.ps1",
    "100-IPReputationLookup.ps1",
    "101-DomainReputationLookup.ps1",
    "102-HashReputationLookup.ps1",
    "103-IOCListNormaliser.ps1",
    "110-CaseFolderBuilder.ps1",
    "111-ResultsToHtmlReport.ps1",
    "112-AttachmentSafeExport.ps1"
)

while ($true) {
    Write-Host "\nSelect a script to run:" 
    for ($i = 0; $i -lt $scripts.Count; $i++) {
        Write-Host ("[{0}] {1}" -f ($i + 1), $scripts[$i])
    }
    Write-Host "[0] Exit"
    $choice = Read-Host "Enter selection"
    if ($choice -eq "0") { break }
    if (-not [int]::TryParse($choice, [ref]$null)) { continue }
    $index = [int]$choice - 1
    if ($index -ge 0 -and $index -lt $scripts.Count) {
        $script = $scripts[$index]
        $argsInput = Read-Host "Enter arguments (or leave blank)"
        if ($argsInput) {
            Invoke-Expression "pwsh ./$script $argsInput"
        } else {
            Invoke-Expression "pwsh ./$script"
        }
    }
}
