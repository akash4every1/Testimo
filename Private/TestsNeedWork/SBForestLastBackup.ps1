﻿<#
$Script:SBForestLastBackup = {
    $LastBackup = Start-TestProcessing -Test "Forest Last Backup Time" -Level 1 -OutputRequired {
        Get-WinADLastBackup
    }
    foreach ($_ in $LastBackup) {
        Test-Value -Level 2 -TestName "Last Backup $($_.NamingContext)" -Object $_ -Property 'LastBackupDaysAgo' -PropertExtendedValue 'LastBackup' -lt -ExpectedValue 2
    }
}
#>

$Script:SBForestLastBackup = {
    Get-WinADLastBackup
}


$Script:SBForestLastBackupTest = {
    foreach ($_ in $Object) {
        Test-Value -Level 6 -TestName "Last Backup $($_.NamingContext)" -Object $_ -Property 'LastBackupDaysAgo' -PropertExtendedValue 'LastBackup' -lt -ExpectedValue 2
    }
}