<#
.SYNOPSIS
  This will remove internet browers user data
.DESCRIPTION
  This script removes all of the user data stored by the browser/s, It first needs
  to stop all of the current browser processes before it can remove the user data.
  It will then attempt to remove all of the user data from the chosen browser/s.
  This script will choose all three browsers if none are chosen from the BrowserType
  parameter.
.Parameter BrowserType
  This parameter has three options Chrome, Firefox and IExplore. These can be entered 
  as an array seperated by commas as per the examples in this help.  
.EXAMPLE
  Remove-BrowserUserData 
  Deletes the user data from Chrome, Firefox and IE (the default targets all three browsers)
.EXAMPLE
  Remove-BrowserUserData -BrowserType IExplore,Chrome
  Deletes the user data from Chrome and IE only
.EXAMPLE
  Remove-BrowserUserData -BrowserType Chrome
  Deletes the user data from Chrome only
.NOTES
  General notes
  Created by: Brent Denny
  Created on:  9 Aug 2019
  Updated on: 12 Aug 2019
#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact='Medium')]
Param(
  [ValidateSet('Chrome','FireFox','IExplore')]
  [string[]]$BrowserType = @('Chrome','FireFox','IExplore')
)
Write-host "`n`n`n"
if ($PSCmdlet.ShouldProcess(($BrowserType -join ' and '), "Terminating processes")) {
  Write-Warning 'Killing all current brower sessions, hopefully?'
  Get-Process | Where-Object {$_.ProcessName -in $BrowserType} | Stop-Process -Force
  $Counter = 0
  do {
    Start-Sleep -Seconds 1
    $Counter++
    $BrowserProcs = Get-Process | Where-Object {$_.ProcessName -in $BrowserType}
  } until ($BrowserProcs.Count -eq 0 -or $Counter -eq 20)
  if ($BrowserProcs.Count -ne 0) {
    Write-Warning "The selected browsers did not terminate in a timely fashion, `nplease close the browsers manually and re-run the script"
    break
  }
}
switch ($BrowserType) {
  {$_ -contains 'Chrome'} {
    if ($PSCmdlet.ShouldProcess('Chrome', "Delete User Data")) {
      $ChromePath = $env:LOCALAPPDATA + "\Google\Chrome\User Data\*"
      if (Test-Path ($env:LOCALAPPDATA + "\Google\Chrome\User Data")) {
        try {
          Write-Warning 'Attempting to clear user data from Chrome'
          Remove-Item -Path $ChromePath -Recurse -Force -ErrorAction stop
        }
        catch {Write-Warning 'Cannot delete the Chrome user data'}
      }
      else {Write-Warning 'No user data exists for the Chrome browser'}
    }
  }
  {$_ -contains 'Firefox'}  {
    if ($PSCmdlet.ShouldProcess('Firefox', "Delete User Data")) {
      if (Test-Path $env:APPDATA\Mozilla\Firefox\Profiles) {
        $FirefoxProfileFolders = (Get-ChildItem $env:APPDATA\Mozilla\Firefox\Profiles\ -Directory).FullName
        Try {
          Write-Warning 'Attempting to clear user data from Chrome Firefox'
          foreach ($ProfDir in $FirefoxProfileFolders) {
            Remove-Item -Recurse -Force -Path $ProfDir\* -ErrorAction stop
          }
        }
        Catch {Write-Warning 'Cannot delete the Firefox user data'}
      }
      else {Write-Warning 'No user data exists for the Firefox browser'}    
    }
  }
  {$_ -contains 'IExplore'} {
    if ($PSCmdlet.ShouldProcess('Internet Explorer', "Delete User Data")) {
      Write-Warning 'Attempting to clear user data from Internet Explorer'
      invoke-command -ScriptBlock {RunDll32.exe InetCpl.cpl, ClearMyTracksByProcess 255}
    }
  }
  Default {Write-Warning 'Failed to clear user data, can only clear user data from Chrome, Firefox and Internet Explorer'}
}
