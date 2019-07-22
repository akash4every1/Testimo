function Test-ImoAD {
    [CmdletBinding()]
    param(
        [switch] $ReturnResults
    )
    $Time = Start-TimeLog
    $Script:TestResults = [System.Collections.Generic.List[PSCustomObject]]::new()

    $Forest = Start-TestProcessing -Test 'Forest Information - Is Available' -ExpectedStatus $true -OutputRequired {
        Get-WinADForest
    }
    Start-TestProcessing -Test "Testing optional features" -Level 1 -Data {
        Get-TestForestOptionalFeatures
    } -Tests {
        Test-Value -TestName 'Is Recycle Bin Enabled?' -Property 'Recycle Bin Enabled' -ExpectedValue $true
        Test-Value -TestName 'is Laps Enabled?' -Property 'Laps Enabled' -ExpectedValue $true
    }

    foreach ($Domain in $Forest.Domains) {

        $DomainInformation = Start-TestProcessing -Test "Domain $Domain - Is Available" -ExpectedStatus $true -OutputRequired -IsTest {
            Get-WinADDomain -Domain $Domain
        }
        $DomainControllers = Start-TestProcessing -Test "Domain Controllers - List is Available" -ExpectedStatus $true -OutputRequired -Level 1 {
            Get-WinADDC -Domain $Domain
        }

        foreach ($_ in $DomainControllers) {

            Start-TestProcessing -Test "Domain Controller - $($_.HostName) | Connectivity Ping $($_.HostName)" -Level 1 -ExpectedStatus $true -IsTest {
                Get-WinTestConnection -Computer $_.HostName
            }
            Start-TestProcessing -Test "Domain Controller - $($_.HostName) | Connectivity Port 53 (DNS)" -Level 1 -ExpectedStatus $true -IsTest {
                Get-WinTestConnectionPort -Computer $_.HostName -Port 53
            }

            <#
            Start-TestProcessing -Test "Domain Controller - $($_.HostName) | Service 'DNS Server'" -Level 2 -ExpectedStatus $true -IsTest {
                Get-WinTestService -Computer $_.HostName -Service 'DNS Server' -Status 'Running'
            }
            Start-TestProcessing -Test "Domain Controller - $($_.HostName) | Service 'Active Directory Domain Services'" -Level 2 -ExpectedStatus $true -IsTest {
                Get-WinTestService -Computer $_.HostName -Service 'Active Directory Domain Services' -Status 'Running'
            }
            Start-TestProcessing -Test "Domain Controller - $($_.HostName) | Service 'Active Directory Web Services'" -Level 2 -ExpectedStatus $true -IsTest {
                Get-WinTestService -Computer $_.HostName -Service 'Active Directory Web Services' -Status 'Running'
            }
            Start-TestProcessing -Test "Domain Controller - $($_.HostName) | Service 'Kerberos Key Distribution Center'" -Level 2 -ExpectedStatus $true -IsTest {
                Get-WinTestService -Computer $_.HostName -Service 'Kerberos Key Distribution Center' -Status 'Running'
            }
            Start-TestProcessing -Test "Domain Controller - $($_.HostName) | Service 'Netlogon'" -Level 2 -ExpectedStatus $true -IsTest {
                Get-WinTestService -Computer $_.HostName -Service 'Netlogon' -Status 'Running'
            }
           #>
            Start-TestProcessing -Test "Testing Services - Domain Controller - $($_.HostName)" -Level 1 -Data {
                $Services = @(
                    'ADWS',
                    #'DHCPServer',
                    'DNS',
                    'DFS',
                    'DFSR',
                    'Eventlog',
                    'EventSystem',
                    'KDC',
                    'LanManWorkstation',
                    'LanManServer',
                    'NetLogon',
                    'NTDS',
                    'RPCSS',
                    'SAMSS',
                    'W32Time'
                )
                Get-PSService -Computers $_ -Services $Services
            } -Tests {
                foreach ($Service in $Services) {
                    Test-Array -TestName "Domain Controller - $($_.HostName) | Service $Service" -SearchObjectProperty 'Name' -SearchObjectValue $Service -Property 'Status' -ExpectedValue 'Running'
                }
            } -Simple
        }
    }
    $Replication = Start-TestProcessing -Test "Forest Replication" -Level 1 -ExpectedStatus $true -OutputRequired {
        Get-WinTestReplication -Status $true
    }
    foreach ($_ in $Replication) {
        Start-TestProcessing -Test "Replication from $($_.Server) to $($_.ServerPartner)" -Level 2 -ExpectedStatus $true -IsTest {
            Get-WinTestReplicationSingular -Replication $_
        }
    }

    $TestsPassed = (($Script:TestResults) | Where-Object { $_.Status -eq $true }).Count
    $TestsFailed = (($Script:TestResults) | Where-Object { $_.Status -eq $false }).Count
    $TestsSkipped = 0
    $TestsInformational = 0

    $EndTime = Stop-TimeLog -Time $Time -Option OneLiner

    Write-Color -Text '[i] ', 'Time to execute tests: ', $EndTime -Color Yellow, DarkGray, Cyan
    Write-Color -Text '[i] ', 'Tests Passed: ', $TestsPassed, ' Tests Failed: ', $TestsFailed, ' Tests Skipped: ', $TestsSkipped -Color Yellow, DarkGray, Green, DarkGray, Red, DarkGray, Cyan

    # This results informaiton in form of Array for future processing
    if ($ReturnResults) {
        $Script:TestResults
    }
}