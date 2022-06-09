# PowerShell LADR error correlation workaround
This [PowerShell](https://github.com/PowerShell/PowerShell/) function is made to assist the user in changing specific mass header values in Agilent 8800X QQQ mass spectrometer output CSV files for the purpose of enabling ratio error correlation calculation and output from LADR for non U-Pb geochronometry. The edited data files should ONLY be used to generate error correlations.

It is a cross-platform function that requires minimal user input via two defined parameters *folderpath* and *decaysystem*. The function has no restrictions on the number of files, and performs the replace operations in parallel to reduce runtime.

## Operational features of the function
* Parameter validation prior to function run
* Creates two new directories in the user defined *folderpath*: 'Originals' and a decaysystem_to_UPb (either "RbSr_to_UPb" or "LuHf_to_UPb" depending on the user defined *decaysystem*)
* Moves all original, unedited CSV files to the 'Originals' folder
* Copies all CSV files in 'Originals' to decaysystem folder
* Runs replace operation on CSV files in decaysystem folder to change Rb85 or Lu175 to U238, Sr87 or Hf176 to Pb207, Sr86 or Hf178 to Pb206, and U238 to U235 (to offset from U238 if measured)

## Adding the function to PowerShell
Firstly, ensure the cross-platform PowerShell Core V7 or higher is installed. See [Get PowerShell](https://github.com/PowerShell/PowerShell#get-powershell) for detailed instructions. It can be installed via most OS package managers (e.g., winget, homebrew, apt).

To obtain this PowerShell function, either clone the repository if you are familiar with Git or download the LADRWorkaround.ps1 file. Place the ps1 file into a stable location (I recommend using Git for this reason and for if I update the code, fix bugs etc.), just place it somewhere you aren't likely to accidentally delete it. GitHub desktop is an easy way to achieve a Git clone without having to use a CLI.

You can either Import-Module Path/LADRWorkaround.ps1 for each session that you need to use it, or to save some time in future I recommend setting up a PowerShell profile if you haven't already. 
To import the function on a session basis, for each session first run (where SomeDirectory is the folderpath where the ps1 file is saved):
```powershell
Import-Module 'SomeDirectory\LADRWorkaround.ps1'
```
To 'permanently' load the function so you do not have to run the previous code each session, first check for a profile file and create one if none exists using the following code:
```powershell
if (!(Test-Path -Path $PROFILE )) { New-Item -Type File -Path $PROFILE -Force }
```
Then open the profile in notepad using:
```powershell
notepad $PROFILE
```
Add the filepath to the LADRWorkaround.ps1 to the profile file that is open in notepad and prefix it with Import-Module:
```powershell
Import-Module 'SomeDirectory\LADRWorkaround.ps1'
```
Save the profile file and close notepad. Now whenever you open the PowerShell terminal it will import the function by default so you can immediately call the function using Edit-LADRWorkaround and you do not need to explicitly run Import-Module each session.

## Using the function
Operation of the function itself is simple, users need to specify a -folderpath and -decaysystem. To call the function the user needs to type Edit-LADRWorkaround in the PowerShell terminal followed by -folderpath 'string' and -decaysystem 'string' where -folderpath needs to be provided as a quote bound string of a path, and -decaysystem a quote bound string of value 'RbSr' or 'LuHf'
```powershell
Edit-LADRWorkaround -folderpath 'C:\Users\UserA\SomeData' -decaysystem 'RbSr'
```

Basic help is available in the function and can be accessed by:
```powershell
help Edit-LADRWorkaround
```
If you've followed these instructions you should be able to quickly process hundreds to thousands of files quickly and easily.