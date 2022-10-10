####################### WoW Cooldown Notifier ##########################
# Name: WoW Cooldown Notifier                                          #
# Desc: Sends Discord Notifications when WoW Crafting Cooldowns are up #
# Author: Ninthwalker                                                  #
# Instructions: https://github.com/ninthwalker/WoWCDNotifier           #
# Date: 10OCT2022                                                      #
# Version: 1.2                                                         #
########################################################################

############################ CHANGE LOG ################################
## 1.0                                                                 #
# Initial App release                                                  #
## 1.1                                                                 #
# Add windows notifications for some events when run manually          #
# Refactor mappings                                                    #
## 1.2                                                                 #
# Use settings file, I think it is easier for the end user             #
########################################################################
 
########################## NOTES FOR USER ##############################
# Used with wow_cd_notifier_settings.txt                               #
# Used in conjunction with this WA: https://wago.io/sluyr3nQ8          #
# Join the WoW CD Notifier discord: https://discord.gg/m3kG5qbtvy      #
# What this does:                                                      #
# Creates a scheduled task on your computer that will upload your wow  #
#  cooldown information to a secure server to process                  #
# This information can then be used to send you an alert in discord    #
#  when your cooldown is ready even when your computer is not on.      #
########################################################################

########################################################################
########            Do not Modify anything below this          #########
########################################################################

# uninstall switch
param ([switch]$removeTask, [switch]$runFromTask)

# paths of this script
$scriptDir = $PSScriptRoot
$scriptPath = $PSCommandPath
if (!$scriptDir) {$scriptDir = (Get-Location).path}
if (!$scriptPath) {($scriptPath = "$(Get-Location)\wow_cd_notifier.ps1")}
$cdPath = "$scriptDir\cdInfo.csv"

# Import settings
Function Get-Settings ([string]$fileName) {
    $data = New-Object PSCustomObject
    switch -regex -file $fileName {
        "^\s*([^#]+?)\s*=\s*(.*)" { # recognize a property
            $name,$value = $matches[1..2]
            $data | Add-Member -Type NoteProperty -Name $name -Value $value
        }
    }
    $data
}
$set = Get-Settings $scriptDir\wow_cd_notifier_settings.txt

if ($set.realmNames -like '*,*') { $set.realmNames = $set.realmNames.Split(',') }
if ($set.charNames -like '*,*') { $set.charNames = $set.charNames.Split(',') }

# create scheduled task if it does not exist
# uses this code to create the task for you:
Function New-CdTask {
    $taskInterval = (New-TimeSpan -Minutes 30)
    $taskTrigger  = New-ScheduledTaskTrigger -Once -At 00:00 -RepetitionInterval $taskInterval
    $taskAction   = New-ScheduledTaskAction -Execute 'mshta' -Argument $taskArgs
    $taskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -StartWhenAvailable -DontStopIfGoingOnBatteries
    Register-ScheduledTask -TaskName $taskName -Action $taskAction -Trigger $taskTrigger -Settings $taskSettings -Description "Sends a discord alert for WoW Profession Cooldowns"
}

#toast notifications - only shown when this is run manually or from shortcut to help with debugging/status
Function New-PopUp {

    param ([string]$msg, [string]$icon)

    [reflection.assembly]::loadwithpartialname('System.Windows.Forms') | Out-Null
    $notify = new-object system.windows.forms.notifyicon
    $notify.BalloonTipTitle = "WoW CD Notifier"
    $notify.icon = [System.Drawing.SystemIcons]::Information
    $notify.visible = $true
    $notify.showballoontip(10,'WoW CD Notifier',$msg,[system.windows.forms.tooltipicon]::$icon)
}

$taskName = "WoW CD Notifier"
$taskArgs =  @"
vbscript:Execute("CreateObject(""WScript.Shell"").Run ""powershell -ExecutionPolicy Bypass & '$scriptPath' -runFromTask"", 0:close")
"@

Function New-Check {
    try {
        $script:task = (get-ScheduledTask -TaskName $taskName -ErrorAction Stop).actions.arguments
        $script:checkTask = $True
    } catch {
        $script:checkTask = $False
    }
}

# check if running from task scheduler to not use toast notifications
if (!$runFromTask) {$canToast = $True}

# verify settings before moving on
$settingsCheck = $set.PSObject.Properties | % { if ($_.value -eq "") {$_.name} }
if ($settingsCheck) {
    if ($canToast) {New-PopUp -msg "Missing Settings! Please fix $settingsCheck" -icon "Warning"}
    Return
}

# remove task when used from shortcut w/ switch
if ($removeTask) {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    Start-Sleep -Seconds 1
    New-Check
    if ($checkTask -and $canToast) {New-PopUp -msg "Uninstall Failed. Please manually check and remove scheduled task" -icon "Warning"}
    elseif (!$checkTask -and $canToast) {
        New-PopUp -msg "Uninstall completed! Scheduled task removed" -icon "Info"
    }
    Return
}

# only run this section if its NOT being run from the scheduled task. sets up the scheduled task
if ($canToast) {

    #check task
    New-Check
    if ($checkTask) {
    
        if ($task -ne $taskArgs) {
            # task path is bad, delete and re-create
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
            Start-Sleep -Seconds 1
            New-CdTask
            Start-Sleep -Seconds 1
            New-Check
            if ( ($checkTask -eq $taskArgs) -and $canToast) {New-PopUp -msg "Setup completed successfully. Have fun!" -icon "Info"}
            elseif ($canToast) {
                New-PopUp -msg "Setup FAILED! Join the discord for help" -icon "Warning"
            }

        }
        elseif ( ($task -eq $taskArgs) -and $canToast) {
            # already configured correctly
            New-PopUp -msg "Setup was already completed. Have fun!" -icon "Info"
        }
    } else {
        New-CdTask
        Start-Sleep -Seconds 1
        New-Check
        Start-Sleep -Seconds 1
        if ( ($task -eq $taskArgs) -and $canToast ) {New-PopUp -msg "Setup completed successfully. Have fun!" -icon "Info"}
        elseif ($canToast) {
            New-PopUp -msg "Setup FAILED! Join the discord for help" -icon "Warning"
        }
    }
}

#only run the rest of code if the file has changed since our last upload
Try {
    $lastFileUpdate = (Get-Item $set.waLuaPath -ErrorAction Stop).LastWriteTime
} Catch {
    if ($canToast) {New-PopUp -msg "Issue with weakauras file. Check that addon is installed and WA path is correct" -icon "Warning"}
    Return
}
Try {
    $lastUpload = (Get-Item $cdPath -ErrorAction SilentlyContinue).LastWriteTime
} Catch {
    # continue
}

if ( $lastFileUpdate -and $lastUpload -and ($lastFileUpdate -eq $lastUpload) ) {
    # no reason to upload
    if ($canToast) { New-PopUp -msg "Cooldown Data was already uploaded. Nothing new" -icon "Info"}
    Return
}

# cd mappings
$cooldownName = @('Primal Might','Brilliant Glass','Ebonweave','Moonshroud','Spellweave','Titansteel')
$cooldownID   = @(29688,47280,56002,56001,56003,55208)
$cooldownIcon = @('spell_nature_lightningoverload.jpg','inv_misc_gem_diamond_03.jpg','inv_fabric_ebonweave.jpg','inv_fabric_moonshroud.jpg','inv_fabric_spellweave.jpg','inv_ingot_titansteel_blue.jpg')
$baseUrl      = "https://render.worldofwarcraft.com/us/icons/56/"
$map = for ($i = 0; $i -lt $cooldownName.count; $i++) {
    [pscustomobject]@{
        ID   = $cooldownID[$i]
        Name = $cooldownName[$i]
        Icon = $baseUrl + $cooldownIcon[$i]
    }
}

# wa data
$cdInfo = @()
$waData = Get-Content -Raw $set.waLuaPath
$set.charNames = $set.charNames | select -Unique

foreach ($server in $set.realmNames) {

    foreach ($toon in $set.charNames) {

        foreach ($ID in $cooldownID) {

            # regex to match on ID and expiration date (which is when it's CD is up) It's in epoch time
            # Its the expiration
            # start with getting the correct realm and character, filter out keyword cooldowns/characters to prevent false positives for toons without CDs 
            # capture groups needed: exp numbers,  server->toon, toon->exp
            $filterServer = $waData -match '(?smi)(?<=cooldownsDb.*?)(' + $server + '.*?' + $toon + '.*?' + $ID + '.*?expiration).*?(\d+\.?\d+)'
            $filterServerMatch = $matches
            $filterChar = $filterServerMatch[0] -match '(?smi)(' + $server +').*?(' + $toon + '.*?' + $ID + '.*?expiration).*?(\d+\.?\d+)'
            $filterCharMatch = $matches

            if ($filterServer -and $filterChar) {
                $verifyServer = select-string -InputObject $filterServerMatch[0] -pattern "characters" -AllMatches
                $verifyChar = select-string -InputObject $filterCharMatch[2] -pattern "cooldowns" -AllMatches
                if ( ($verifyChar.Matches.count -eq 1) -and ($verifyServer.Matches.count -eq 1) ) {
                    # match is good
                    $epoch = $filterServerMatch[2]
                } else {
                    $epoch = $false
                }

                if ($epoch) {
                    $mapMatch = $map | ? {$_.ID -eq $ID}
                    # add expiration info into PS object
                    $cdInfo += [psCustomObject]@{
                        'name' = $mapMatch.Name
                        'id'   = $ID
                        'time' = ([datetimeoffset]::FromUnixTimeSeconds($epoch)).UtcDateTime
                        'realm' = $server
                        'char' = $toon
                        'icon' = $mapMatch.Icon
                        'link' = "https://www.wowhead.com/spell=" + $ID
                        'alertTime' = $set.alertTime
                        'interval' = $set.interval
                        'intervalTime' = $set.intervalTime
                        'keepBuggingMe' = $set.keepBuggingMe
                        'discordId' = $set.discordId
                        'timeOffset' = ([datetimeoffset]::now).Offset.Hours
                    }
                }
            }
        }
    } 
}

if ($cdInfo) {
    # export
    $cdInfo | Export-Csv -Path $cdPath -Force -NoTypeInformation

    # upload
    # needs pwsh to use -Form. Otherwise use curl.exe which was included with win 10 version 17063 (April 2018 update)
    #$form = @{
    #    data = Get-Item -Path $cdPath
    #}
    #$upload = Invoke-WebRequest -Uri wowcd.ninthwalker.dev?/upload?key=$($set.token) -Method Post -Form $form
    $upload = curl.exe --silent -XPOST -F "data=@$cdPath" https://wowcd.ninthwalker.dev/upload?key=$($set.token)
    # update modtime to use for existing checks
    if ($upload -eq "Upload successful") {
        $lastFileUpdate = (Get-Item $set.waLuaPath).LastWriteTime
        (Get-Item $cdPath).LastWriteTime = $lastFileUpdate
    } elseif ($canToast) {
        New-PopUp -msg "Upload FAILED! Join the discord for help. Error: $upload" -icon "Warning"
    }
}
