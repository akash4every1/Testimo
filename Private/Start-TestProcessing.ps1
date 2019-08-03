﻿function Start-TestProcessing {
    [CmdletBinding()]
    param(
        #  [parameter(ParameterSetName = "Manual")]
        [ScriptBlock] $Execute,
        [ScriptBlock] $Data,
        [ScriptBlock] $Tests,
        [string] $Test,
        [switch] $OutputRequired,
        [nullable[bool]] $ExpectedStatus,
        [int] $Level = 0,
        [switch] $IsTest,
        [switch] $Simple
    )

    if ($Execute) {
        if ($IsTest) {
            Write-Color '[t] ', $Test -Color Cyan, Yellow, Cyan -NoNewLine -StartSpaces ($Level * 3)
        } else {
            Write-Color '[i] ', $Test -Color Cyan, DarkGray, Cyan -NoNewLine -StartSpaces ($Level * 3)
        }

        [Array] $Output = & $Execute
        foreach ($O in $Output) {
            if ($OutputRequired.IsPresent) {
                if ($O['Output']) {
                    foreach ($_ in $O['Output']) {
                        $_
                    }
                } else {
                    foreach ($_ in $O) {
                        $_
                    }
                }
            }
        }
        if ($null -eq $ExpectedStatus) {
            Write-Color -Text ' [', 'Informative', ']' -Color Cyan, DarkGray, Cyan
        } elseif ($ExpectedStatus -eq $O.Status) {
            if ($O.Extended) {
                Write-Color -Text ' [', 'Pass', ']', " [", $O.Extended, "]" -Color Cyan, Green, Cyan, Cyan, Green, Cyan
            } else {
                Write-Color -Text ' [', 'Pass', ']' -Color Cyan, Green, Cyan #, Cyan, Green, Cyan
            }
        } else {
            if ($O.Extended) {
                Write-Color -Text ' [', 'Fail', ']', " [", $O.Extended, "]" -Color Cyan, Red, Cyan, Cyan, Red, Cyan
            } else {
                Write-Color -Text ' [', 'Fail', ']' -Color Cyan, Red, Cyan #, Cyan, Green, Cyan
            }
        }

        $Script:TestResults.Add(
            [PSCustomObject]@{
                Test     = $Test
                Status   = $ExpectedStatus -eq $Output.Status
                Extended = $Output.Extended
            }
        )
    }

    if ($Data) {
        Write-Color '[i] ', $Test -Color Cyan, DarkGray, White -StartSpaces ($Level * 3) -NoNewLine
        [Array] $OutputData = & $Data
        if (-not $Simple) {
            $GatheredData = $OutputData.Output

            if ($Output.Output -and $OutputData.Status -eq $false) {
                if ($OutputData.Extended) {
                    Write-Color -Text ' [', 'Fail', ']', " [", $Output.Extended, "]" -Color Cyan, Red, Cyan, Cyan, Red, Cyan
                } else {
                    Write-Color -Text ' [', 'Fail', ']' -Color Cyan, Red, Cyan #, Cyan, Green, Cyan
                }
            } else {
                if ($OutputData.Extended) {
                    Write-Color -Text ' [', 'Pass', ']', " [", $Output.Extended, "]" -Color Cyan, Green, Cyan, Cyan, Green, Cyan
                } else {
                    Write-Color -Text ' [', 'Pass', ']' -Color Cyan, Green, Cyan #, Cyan, Green, Cyan
                }
            }
        } else {
            try {
                $GatheredData = $OutputData
                Write-Color -Text ' [', 'Pass', ']' -Color Cyan, Green, Cyan #, Cyan, Green, Cyan
            } catch {
                $ErrorMessage = $_.Exception.Message -replace "`n", " " -replace "`r", " "
                Write-Color -Text ' [', 'Fail', ']', " [", $ErrorMessage, "]" -Color Cyan, Red, Cyan, Cyan, Red, Cyan
            }
        }

        [Array] $TestsExecution = & $Tests
        foreach ($_ in $TestsExecution) {
            if ($_.Type -eq 'Hash') {
                $Value = $GatheredData.$($_.Property)
                if ($Value -eq $_.ExpectedValue) {
                    Write-Color -Text '[t] ', $_.TestName, ' [', 'Passed', ']', " [", $Value, "]" -Color Cyan, Green, Cyan, Cyan, Green, Cyan -StartSpaces ($Level * 6)
                } else {
                    Write-Color -Text '[t] ', $_.TestName, ' [', 'Fail', ']', " [", $Value, "]" -Color Cyan, Red, Cyan, Red, Cyan, Cyan, Red, Cyan, Red, Cyan -StartSpaces ($Level * 6)
                }
            } elseif ($_.Type -eq 'Array') {

                foreach ($Object in $GatheredData) {
                    if ($Object.$($_.SearchObjectProperty) -eq $_.SearchObjectValue) {
                        $Value = $Object.$($_.Property)
                        if ($Value -eq $_.ExpectedValue) {
                            Write-Color -Text '[t] ', $_.TestName, ' [', 'Passed', ']', " [", $Value, "]" -Color Cyan, Yellow, Cyan, Green, Cyan, Cyan, Green, Cyan -StartSpaces ($Level * 6)
                            $Script:TestResults.Add(
                                [PSCustomObject]@{
                                    Test     = $_.TestName
                                    Status   = $True
                                    Extended = $Value
                                }
                            )
                        } else {
                            Write-Color -Text '[t] ', $_.TestName, ' [', 'Fail', ']', " [", $Value, "]" -Color Cyan, Red, Cyan, Red, Cyan, Cyan, Red, Cyan -StartSpaces ($Level * 6)
                            $Script:TestResults.Add(
                                [PSCustomObject]@{
                                    Test     = $_.TestName
                                    Status   = $False
                                    Extended = $Value
                                }
                            )
                        }

                    }

                }


            }
        }

    }
}