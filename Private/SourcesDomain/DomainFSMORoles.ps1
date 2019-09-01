﻿$DomainFSMORoles = @{
    Enable = $true
    Source = @{
        Name       = 'Roles availability'
        Data       = {
            Test-ADRolesAvailability -Domain $Domain
        }
        Details = [ordered] @{
            Area             = ''
            Explanation      = ''
            Recommendation   = ''
            RiskLevel        = 10
            RecommendedLinks = @(

            )
        }
    }
    Tests  = [ordered] @{
        PDCEmulator          = @{
            Enable     = $true
            Name       = 'PDC Emulator Availability'
            Parameters = @{
                ExpectedValue         = $true
                Property              = 'PDCEmulatorAvailability'
                OperationType         = 'eq'
                PropertyExtendedValue = 'PDCEmulator'
            }
        }
        RIDMaster            = @{
            Enable     = $true
            Name       = 'RID Master Availability'
            Parameters = @{
                ExpectedValue         = $true
                Property              = 'RIDMasterAvailability'
                OperationType         = 'eq'
                PropertyExtendedValue = 'RIDMaster'
            }
        }
        InfrastructureMaster = @{
            Enable     = $true
            Name       = 'Infrastructure Master Availability'
            Parameters = @{
                ExpectedValue         = $true
                Property              = 'InfrastructureMasterAvailability'
                OperationType         = 'eq'
                PropertyExtendedValue = 'InfrastructureMaster'
            }
        }
    }
}