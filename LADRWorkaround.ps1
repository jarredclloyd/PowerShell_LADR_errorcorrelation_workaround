<#
FILENAME: LADRWorkaround.ps1
VERSION 1.0.2
POWERSHELL FUNCTION NAME: Edit-LADRWorkaround
AUTHOR: Jarred Lloyd
DATE: 2022-06-09
PROJECTURI = 'https://github.com/jarredclloyd/PowerShell_LADR_errorcorrelation_workaround

    Copyright (C) 2022 Jarred Lloyd

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
#>

<#
.SYNOPSIS
Quickly batch edit specific headers in Agilent 8800x mass spectrometer output files as a workaround to calculate error correlations in LADR for RbSr and LuHf geochronometry.

.DESCRIPTION
This function allows the user to quickly batch alter specific headers in Agilent 8800x mass spectrometer output CSV files as a workaround to calculate error correlations in LADR for RbSr and LuHf geochronometry. 
The user only needs to pass two variables $folderpath and $decaysystem for the function to operate. If one of these parameters is not set correctly or missing the function will throw an error.
Given the two parameters, the function will create two new directories 'Originals' and one for the decay system (e.g., 'RbSr_norm_to_UPb' OR 'LuHf_to_UPb'). It will then move all the original CSV files into 'Originals' and subsequently copy them to the decay system folder.
If the decay system folder already exists, the function will end without any alterations. If the folder does not exist it will proceed to make the required changes to the CSV files in the decay system folder. 
For decay system:
'RbSrNorm', 'RbSrInv': 'Rb85 -> 85' will be replaced by 'U238', 'Sr87 -> 103' will be replaced by 'Pb207', and 'Sr86 -> 102' will be replaced by 'Pb206'. The 'inv' version will switch Sr87 and Sr86 transforms. Additonally 'U238 ->....' will be replaced by 'U234'.
'RbSr88Norm', 'RbSr88Inv': Same as RbSr but Sr88 replaces Sr86 (used for low Sr86 Sr88 samples)
'LuHfNorm', 'LuHfInv': 'Lu175 -> 175' will be replaced by 'U238', 'Hf176 -> 258' will be replaced by 'Pb207, and 'Hf178 -> 260' will be replaced by 'Pb206'. The 'inv' version will switch Hf176 and Hf178 transforms. Additonally 'U238 ->....' will be replaced by 'U234'.

.PARAMETER decaysystem
This parameter is used to define the geochronometric decay system the data is used for to correctly adjust headers. Set to a value of 'RbSr' or 'LuHf' (e.g., -decaysystem 'RbSr')

.PARAMETER folderpath
This parameter is used to define the host folder path the data to be copied and edited is stored in. Set to a path string (e.g., -folderpath 'C:\Users\UserA\' or 'C:/Users/UserA')

.EXAMPLE
PS> Edit-LADRWorkaround -folderpath 'C:\Users\UserA\somedata' -decaysystem 'RbSr'
#>

function Edit-LADRWorkaround {
    param (
        [Parameter(Mandatory)]
        [ValidateSet('RbSrNorm', 'RbSrInv' , 'RbSr88Norm', 'RbSr88Inv' , 'LuHfNorm', 'LuHfInv')]
        [string]$decaysystem
    ,
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path $_ -PathType 'Container' })]
        [string]$folderpath
    )
    process {
    $LuHfNormtoUPbDir = Join-Path -Path $folderpath -ChildPath 'LuHf_norm_to_UPb'
    $LuHfInvtoUPbDir = Join-Path -Path $folderpath -ChildPath 'LuHf_inv_to_UPb'
    $RbSrNormtoUPbDir= Join-Path -Path $folderpath -ChildPath 'RbSr_norm_to_UPb'
    $RbSrInvtoUPbDir = Join-Path -Path $folderpath -ChildPath 'RbSr_inv_to_UPb'
    $RbSr88NormtoUPbDir = Join-Path -Path $folderpath -ChildPath 'RbSr88_norm_to_UPb'
    $RbSr88InvtoUPbDir = Join-Path -Path $folderpath -ChildPath 'RbSr88_inv_to_UPb'
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
            'RbSrNorm' {
                if (Test-Path $RbSrNormtoUPbDir) {
                    Write-Host 'Edited files folder already exists. Operation terminated.' 
            } 
                else { 
                    New-Item $RbSrNormtoUPbDir -ItemType Directory
                    Copy-Item -Path $originalsdircsv -Destination $RbSrNormtoUPbDir
                    Get-ChildItem -Path $RbSrNormtoUPbDir| ForEach-Object -ThrottleLimit 16 -Parallel {
                        $outfile = $_.FullName 
                        [io.file]::ReadAllText($_.FullName) `
                        -Replace 'Rb85 -> 85', 'U238' -Replace 'Sr87 -> 103', 'Pb207' -Replace 'Sr86 -> 102', 'Pb206' `
                        -Replace 'U238 ->....', 'U234' -Replace 'U235 ->....', 'U232' `
                        -Replace 'Pb206 ->....', 'Pb202' -Replace 'Pb207 ->....', 'Pb205'|
                        Out-File $outfile
                    }
                    Write-Host 'Task completed.'
                }
            }
            'RbSrInv' {
                if (Test-Path $RbSrInvtoUPbDir) {
                    Write-Host 'Edited files folder already exists. Operation terminated.' 
                } 
                else { 
                    New-Item $RbSrInvtoUPbDir -ItemType Directory
                    Copy-Item -Path $originalsdircsv -Destination $RbSrInvtoUPbDir
                    Get-ChildItem -Path $RbSrInvtoUPbDir | ForEach-Object -ThrottleLimit 16 -Parallel {
                        $outfile = $_.FullName 
                        [io.file]::ReadAllText($_.FullName) `
                        -Replace 'Rb85 -> 85', 'U238' -Replace 'Sr87 -> 103', 'Pb206' -Replace 'Sr86 -> 102', 'Pb207' `
                        -Replace 'U238 ->....', 'U234' -Replace 'U235 ->....', 'U232' `
                        -Replace 'Pb206 ->....', 'Pb202' -Replace 'Pb207 ->....', 'Pb205' |
                        Out-File $outfile
                    }
                    Write-Host 'Task completed.'
                }
            }
            'RbSr88Norm' {
                if (Test-Path $RbSr88NormtoUPbDir) {
                    Write-Host 'Edited files folder already exists. Operation terminated.' 
                } 
                else { 
                    New-Item $RbSr88NormtoUPbDir -ItemType Directory
                    Copy-Item -Path $originalsdircsv -Destination $RbSr88NormtoUPbDir
                    Get-ChildItem -Path $RbSr88NormtoUPbDir | ForEach-Object -ThrottleLimit 16 -Parallel {
                        $outfile = $_.FullName 
                        [io.file]::ReadAllText($_.FullName) `
                        -Replace 'Rb85 -> 85', 'U238' -Replace 'Sr87 -> 103', 'Pb207' -Replace 'Sr88 -> 104', 'Pb206' `
                        -Replace 'U238 ->....', 'U234' -Replace 'U235 ->....', 'U232' `
                        -Replace 'Pb206 ->....', 'Pb202' -Replace 'Pb207 ->....', 'Pb205' |
                        Out-File $outfile
                        }
                    Write-Host 'Task completed.'
                }
            }
            'RbSr88Inv' {
                if (Test-Path $RbSr88InvtoUPbDir) {
                    Write-Host 'Edited files folder already exists. Operation terminated.' 
                } 
                else { 
                    New-Item $RbSr88InvtoUPbDir -ItemType Directory
                    Copy-Item -Path $originalsdircsv -Destination $RbSr88InvtoUPbDir
                    Get-ChildItem -Path $RbSr88InvtoUPbDir | ForEach-Object -ThrottleLimit 16 -Parallel {
                        $outfile = $_.FullName 
                        [io.file]::ReadAllText($_.FullName) `
                        -Replace 'Rb85 -> 85', 'U238'` -Replace 'Sr87 -> 103', 'Pb206' -Replace 'Sr88 -> 104', 'Pb207' `
                        -Replace 'U238 ->....', 'U234' -Replace 'U235 ->....', 'U232' `
                        -Replace 'Pb206 ->....', 'Pb202' -Replace 'Pb207 ->....', 'Pb205' |
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
                        [io.file]::ReadAllText($_.FullName) `
                        -Replace 'Lu175 -> 175', 'U238' -Replace 'Hf176 -> 258', 'Pb207' -Replace 'Hf178 -> 260', 'Pb206'`
                        -Replace 'U238 ->....', 'U234' -Replace 'U235 ->....', 'U232' `
                        -Replace 'Pb206 ->....', 'Pb202' -Replace 'Pb207 ->....', 'Pb205' |
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
                        [io.file]::ReadAllText($_.FullName) `
                        -Replace 'Lu175 -> 175', 'U238' -Replace 'Hf176 -> 258', 'Pb206' -Replace 'Hf178 -> 260', 'Pb207'`
                        -Replace 'U238 ->....', 'U234' -Replace 'U235 ->....', 'U232' `
                        -Replace 'Pb206 ->....', 'Pb202' -Replace 'Pb207 ->....', 'Pb205' |
                        Out-File $outfile
                        }
                    Write-Host 'Task completed.'
                }
            }
        }
    }
}