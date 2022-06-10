<#
FILENAME: LADRWorkaround.ps1
VERSION 1.0.0
POWERSHELL FUNCTION NAME: Edit-LADRWorkaround
AUTHOR: Jarred Lloyd
DATE: 2022-06-09
PROJECTURI = 'https://github.com/jarredclloyd/PowerShell_LADR_errorcorrelation_workaround
#>

<#
.SYNOPSIS
Quickly batch edit specific headers in Agilent 8800x mass spectrometer output files as a workaround to calculate error correlations in LADR for RbSr and LuHf geochronometry.

.DESCRIPTION
This function allows the user to quickly batch alter specific headers in Agilent 8800x mass spectrometer output CSV files as a workaround to calculate error correlations in LADR for RbSr and LuHf geochronometry. 
The user only needs to pass two variables $folderpath and $decaysystem for the function to operate. If one of these parameters is not set correctly or missing the function will throw an error.
Given the two parameters, the function will create two new directories 'Originals' and one for the decay system (either 'RbSr_to_UPb' OR 'LuHf_to_UPb'). It will then move all the original CSV files into 'Originals' and subsequently copy them to the decay system folder.
If the decay system folder already exists, the function will end without any alterations. If the folder does not exist it will proceed to make the required changes to the CSV files in the decay system folder. 
For decay system:
'RbSr', 'Rb85 -> 85' will be replaced by 'U238', 'Sr87 -> 103' will be replaced by 'Pb207, and 'Sr86 -> 102' will be replaced by 'Pb206'. Additonally 'U238 ->....' will be replaced by 'U234'.
'LuHf', 'Lu175 -> 175' will be replaced by 'U238', 'Hf176 -> 258' will be replaced by 'Pb207, and 'Hf178 -> 260' will be replaced by 'Pb206'. Additonally 'U238 ->....' will be replaced by 'U234'.

.PARAMETER decaysystem
This parameter is used to define the geochronometric decay system the data is used for to correctly adjust headers. Set to a value of 'RbSr' or 'LuHf' (e.g., -decaysystem 'RbSr')

.PARAMETER folderpath
This parameter is used to define the host folder path the data to be copied and edited is stored in. Set to a path string (e.g., -folderpath 'C:\Users\UserA\' or 'C:/Users/UserA')

.EXAMPLE
PS> Edit-LADRWorkaround -path 'C:\Users\UserA\somedata' -decaysystem 'RbSr'
#>

function Edit-LADRWorkaround {
    param (
        [Parameter(Mandatory)]
        [ValidateSet('RbSr', 'LuHfNorm', 'LuHfInv')]
        [string]$decaysystem
    ,
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path $_ -PathType 'Container' })]
        [string]$folderpath
    )
    process {
    $LuHfNormtoUPbDir = Join-Path -Path $folderpath -ChildPath 'LuHf_norm_to_UPb'
    $LuHfInvtoUPbDir = Join-Path -Path $folderpath -ChildPath 'LuHf_inv_to_UPb'
    $RbSrtoUPbDir = Join-Path -Path $folderpath -ChildPath 'RbSr_to_UPb'
    $originalsdir = Join-Path -Path $folderpath -ChildPath 'Originals'
    $folderpathcsv = Join-Path -Path $folderpath -ChildPath '*.csv'
    $originalsdircsv = Join-Path -Path $originalsdir -ChildPath '*.csv'

    if (Test-Path $originalsdir) {
        Write-Host 'Originals folder already exists'
    }
    else {
        New-Item $originalsdir -ItemType Directory
        Move-Item -Path $folderpathcsv -Destination $originalsdir
    }
    switch ($decaysystem) {
            'RbSr' { if (Test-Path $RbSrtoUPbDir) {
                Write-Host 'Edited files folder already exists. Operation terminated.' 
            } 
                else { 
                New-Item $RbSrtoUPbDir -ItemType Directory
                Copy-Item -Path $originalsdircsv -Destination $RbSrtoUPbDir
                    Get-ChildItem -Path $RbSrtoUPbDir| ForEach-Object -ThrottleLimit 16 -Parallel {
                        $outfile = $_.FullName 
                        [io.file]::ReadAllText($_.FullName) -Replace 'Rb85 -> 85', 'U238' -Replace 'Sr87 -> 103', 'Pb207' -Replace 'Sr86 -> 102', 'Pb206' -Replace 'U238 ->....', 'U234' |
                        Out-File $outfile
                    }
                    Write-Host 'Task completed.'
                }
            }
            'LuHfNorm' { if (Test-Path $LuHfNormtoUPbDir) {
                    Write-Host 'Edited files folder already exists. Operation terminated.' 
            } 
                else { 
                    New-Item $LuHfNormtoUPbDir -ItemType Directory
                    Copy-Item -Path $originalsdircsv -Destination $LuHfNormtoUPbDir
                    Get-ChildItem -Path $LuHfNormtoUPbDir | ForEach-Object -ThrottleLimit 16 -Parallel {
                        $outfile = $_.FullName 
                                [io.file]::ReadAllText($_.FullName) -Replace 'Lu175 -> 175', 'U238' -Replace 'Hf176 -> 258', 'Pb207' -Replace 'Hf178 -> 260', 'Pb206' -Replace 'U238 ->....', 'U234' |
                        Out-File $outfile
                    }
                    Write-Host 'Task completed.'
                }
            }
            'LuHfInv' {
                if (Test-Path $LuHfInvtoUPbDir) {
                    Write-Host 'Edited files folder already exists. Operation terminated.' 
                } 
                else { 
                    New-Item $LuHfInvtoUPbDir -ItemType Directory
                    Copy-Item -Path $originalsdircsv -Destination $LuHfInvtoUPbDir
                    Get-ChildItem -Path $LuHfInvtoUPbDir | ForEach-Object -ThrottleLimit 16 -Parallel {
                        $outfile = $_.FullName 
                                    [io.file]::ReadAllText($_.FullName) -Replace 'Lu175 -> 175', 'U238' -Replace 'Hf176 -> 258', 'Pb206' -Replace 'Hf178 -> 260', 'Pb207' -Replace 'U238 ->....', 'U234' |
                            Out-File $outfile
                        }
                        Write-Host 'Task completed.'
                    }
                }
        }
    }
}