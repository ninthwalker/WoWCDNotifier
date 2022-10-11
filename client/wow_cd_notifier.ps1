####################### WoW Cooldown Notifier ##########################
# Name: WoW Cooldown Notifier                                          #
# Desc: Sends Discord Notifications when WoW Crafting Cooldowns are up #
# Author: Ninthwalker                                                  #
# Instructions: https://github.com/ninthwalker/WoWCDNotifier           #
# Date: 11OCT2022                                                      #
# Version: 1.3                                                         #
########################################################################

########################### CHANGE LOG #################################
## 1.0                                                                 #
# Initial App release                                                  #
## 1.1                                                                 #
# Add windows notifications for some events when run manually          #
# Refactor mappings                                                    #
## 1.2                                                                 #
# Use settings file, I think it is easier for the end user             #
## 1.3                                                                 #
# use winform for more user friendliness. I'm such a nice guy!         #
########################################################################
 
######################### NOTES FOR USER ###############################
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

#check task to see what gui to show at start
param ([switch]$runFromTask)

if (!$runFromTask) {
    $canToast = $True
    # form imports
    Add-Type -AssemblyName System.Windows.Forms,System.Drawing
}

# paths of this script
$scriptDir = $PSScriptRoot
$scriptPath = $PSCommandPath
if (!$scriptDir) {$scriptDir = (Get-Location).path}
if (!$scriptPath) {($scriptPath = "$(Get-Location)\wow_cd_notifier.ps1")}
$cdPath = "$scriptDir\cdInfo.csv"

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

if ($canToast) {
    #check task
    New-Check
    if ($checkTask) {
        if ($task -ne $taskArgs) {
            # task settings are bad. Show install button
            $gui = "install"
        } elseif ($task -eq $taskArgs) {
            # task is good, show uninstall button
            $gui = "uninstall"
        }
    } else {
        # no task found, show install button
        $gui = "install" 
    }
}

#toast notifications - only shown when this is run manually or from shortcut to help with debugging/status
Function New-PopUp {

    param ([string]$msg, [string]$icon)

    $notify = new-object system.windows.forms.notifyicon
    $notify.BalloonTipTitle = "WoW CD Notifier"
    $notify.icon = [System.Drawing.SystemIcons]::Information
    $notify.visible = $true
    $notify.showballoontip(10,'WoW CD Notifier',$msg,[system.windows.forms.tooltipicon]::$icon)
}

Function Start-Debug {
    #start powershell {& $scriptPath -noprofile -noexit -ExecutionPolicy Bypass}
    $argList = "-noprofile -noexit -ExecutionPolicy Bypass -file `"$scriptPath`""
    Start-Process powershell -argumentlist $argList
}

# wowcdnotifier funcion
Function Start-WowCdNotifier {

    # Disable buttons and clear status
    $button_install.Enabled = $False
    $label_status.ForeColor = "#ffff00"
    $label_status.text = "Installing .."
    $label_status.Refresh()
    Start-Sleep -Seconds 1

    # create scheduled task if it does not exist
    # uses this code to create the task for you:
    Function New-CdTask {
        $taskInterval = (New-TimeSpan -Minutes 30)
        $taskTrigger  = New-ScheduledTaskTrigger -Once -At 00:00 -RepetitionInterval $taskInterval
        $taskAction   = New-ScheduledTaskAction -Execute 'mshta' -Argument $taskArgs
        $taskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -StartWhenAvailable -DontStopIfGoingOnBatteries
        Register-ScheduledTask -TaskName $taskName -Action $taskAction -Trigger $taskTrigger -Settings $taskSettings -Description "Sends a discord alert for WoW Profession Cooldowns"
    }

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

    if (Test-Path $scriptDir\wow_cd_notifier_settings.txt) {
        $set = Get-Settings $scriptDir\wow_cd_notifier_settings.txt
    } else {
        New-PopUp -msg "Couldn't find settings file. Please check settings!" -icon "Warning"
        $label_status.ForeColor = "#ffff00"
        $label_status.text = "Couldn't find settings file.`r`nPlease Check settings and try again."
        $label_status.Refresh()
        $button_install.Enabled = $True
        Return
    }

    if ($set.realmNames -like '*,*') { $set.realmNames = $set.realmNames.Split(',') }
    if ($set.charNames -like '*,*') { $set.charNames = $set.charNames.Split(',') }

    # verify settings before moving on
    $settingsCheck = $set.PSObject.Properties | % { if ($_.value -eq "") {$_.name} }
    if ($settingsCheck) {
        if ($canToast) {
            New-PopUp -msg "Missing Settings! Please fix $settingsCheck" -icon "Warning"
            $label_status.ForeColor = "#ffff00"
            $label_status.text = "Missing Settings! Please fix:`r`n$settingsCheck"
            $label_status.Refresh()
            $button_install.Enabled = $True
            Return
        }
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
                if ( ($checkTask -eq $taskArgs) -and $canToast) {
                    New-PopUp -msg "Install completed successfully. Have fun!" -icon "Info"
                    $goodInstall = $True
                    $label_status.ForeColor = "#7CFC00"
                    $label_status.text = "Install completed successfully.`r`nHave fun!"
                    $label_status.Refresh()
                }
                elseif ($canToast) {
                    New-PopUp -msg "INSTALL FAILED! Join the discord for help" -icon "Warning"
                    $label_status.ForeColor = "#ff0000"
                    $label_status.text = "Install Failed!!.`r`nClick the discord link below for help."
                    $label_status.Refresh()
                    $button_install.Enabled = $True
                }

            } elseif ( ($task -eq $taskArgs) -and $canToast) {
                # already configured correctly
                New-PopUp -msg "Install was already completed. Everything looks good, have fun!" -icon "Info"
                $goodInstall = $True
                $label_status.ForeColor = "#7CFC00"
                $label_status.text = "Install was already completed.`r`nEverything looks good, have fun!"
                $label_status.Refresh()
            }
        } else {
            New-CdTask
            Start-Sleep -Seconds 1
            New-Check
            Start-Sleep -Seconds 1
            if ( ($task -eq $taskArgs) -and $canToast ) {
                New-PopUp -msg "Install completed successfully. Have fun!" -icon "Info"
                $goodInstall = $True
                $label_status.ForeColor = "#7CFC00"
                $label_status.text = "Install completed successfully.`r`nHave fun!"
                $label_status.Refresh()
            }
            elseif ($canToast) {
                New-PopUp -msg "Install Failed! Join the discord for help" -icon "Warning"
                $label_status.ForeColor = "ff0000"
                $label_status.text = "Install Failed!`r`nClick the Discord link below for help."
                $label_status.Refresh()
                $button_install.Enabled = $True
            }
        }
    }

    #only run the rest of code if the file has changed since our last upload
    Try {
        $lastFileUpdate = (Get-Item $set.waLuaPath -ErrorAction Stop).LastWriteTime
    } Catch {
        if ($canToast) {
            New-PopUp -msg "Issue with weakauras file. Check that addon is installed and WA path is correct." -icon "Warning"
            $label_status.ForeColor = "ffff00"
            $label_status.text = "Issue with Weakauras file.`r`nCheck that addon is installed and WA path is correct."
            $label_status.Refresh()
            $button_install.Enabled = $True  
        }
        Return
    }
    Try {
        $lastUpload = (Get-Item $cdPath -ErrorAction SilentlyContinue).LastWriteTime
    } Catch {
        # continue
    }

    if ( $lastFileUpdate -and $lastUpload -and ($lastFileUpdate -eq $lastUpload) ) {
        # no reason to upload
        if ($canToast -and !$goodInstall) { 
            New-PopUp -msg "Cooldown Data was already uploaded. Nothing new" -icon "Info"
            $label_status.ForeColor = "#7CFC00"
            $label_status.text = "Cooldown Data was already uploaded.`r`nNothing new."
            $label_status.Refresh()
        }
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
            $label_status.ForeColor = "#ff0000"
            $label_status.text = "Upload Failed!`r`nClick the Discord link below to get help."
            $label_status.Refresh()
            $button_install.Enabled = $True
        }
    }
}

# remove task
Function Remove-WoWCdNotifier {

    # Disable buttons and clear status
    $button_uninstall.Enabled = $False
    $label_status.ForeColor = "#ffff00"
    $label_status.text = "Uninstalling .."
    $label_status.Refresh()
    Start-Sleep -Seconds 1

    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    Start-Sleep -Seconds 1
    New-Check
    if ($checkTask -and $canToast) {
        New-PopUp -msg "Uninstall Failed. Please manually check and remove scheduled task" -icon "Warning"
            $label_status.ForeColor = "ff0000"
            $label_status.text = "Uninstall Failed!`r`nPlease manually check and remove scheduled task."
            $label_status.Refresh()
            $button_uninstall.Enabled = $True
    }
    elseif (!$checkTask -and $canToast) {
        New-PopUp -msg "Uninstall completed! Scheduled task has been removed" -icon "Info"
        $label_status.ForeColor = "#7CFC00"
        $label_status.text = "Uninstall completed!`r`nScheduled task has been removed."
        $label_status.Refresh()
    }
    Return
}

    if ($canToast) {
    # Form section
    $form                           = New-Object System.Windows.Forms.Form
    $form.Text                      ='WoW CD Notifier'
    $form.Width                     = 300
    $form.Height                    = 180
    $form.AutoSize                  = $True
    $form.MaximizeBox               = $False
    $form.BackColor                 = "#4a4a4a"
    $form.TopMost                   = $False
    $form.StartPosition             = 'CenterScreen'
    $form.FormBorderStyle           = "FixedDialog"
    $form.MinimizeBox               = $False

    # install Button
    $button_install                   = New-Object system.Windows.Forms.Button
    $button_install.BackColor         = "#f5a623"
    $button_install.text              = "Install"
    $button_install.width             = 120
    $button_install.height            = 50
    $button_install.location          = New-Object System.Drawing.Point(85,15)
    $button_install.Font              = 'Microsoft Sans Serif,11,style=Bold'
    $button_install.FlatStyle         = "Flat"
    if ($gui -eq "install") {$button_install.Enabled = $True} else{$button_install.Enabled = $False}
    if ($gui -eq "install") {$button_install.Visible = $True} else{$button_install.Visible = $False}

    # uninstall Button
    $button_uninstall                    = New-Object system.Windows.Forms.Button
    $button_uninstall.BackColor          = "#f5a623"
    $button_uninstall.ForeColor          = "#FF0000"
    $button_uninstall.text               = "Uninstall"
    $button_uninstall.width              = 120
    $button_uninstall.height             = 50
    $button_uninstall.location           = New-Object System.Drawing.Point(85,15)
    $button_uninstall.Font               = 'Microsoft Sans Serif,11,style=Bold'
    $button_uninstall.FlatStyle          = "Flat"
    if ($gui -eq "uninstall") {$button_uninstall.Enabled = $True} else{$button_uninstall.Enabled = $False}
    if ($gui -eq "uninstall") {$button_uninstall.Visible = $True} else{$button_uninstall.Visible = $False}

    # Status label
    $label_status                   = New-Object system.Windows.Forms.Label
    $label_status.text              = ""
    $label_status.AutoSize          = $True
    $label_status.width             = 30
    $label_status.height            = 20
    $label_status.location          = New-Object System.Drawing.Point(5,75)
    $label_status.Font              = 'Microsoft Sans Serif,10,style=Bold'
    $label_status.ForeColor         = "#7CFC00"

    # version link
    $label_version            = New-Object system.Windows.Forms.LinkLabel
    $label_version.text       = "v1.2"
    $label_version.AutoSize   = $True
    $label_version.width      = 30
    $label_version.height     = 20
    $label_version.location   = New-Object System.Drawing.Point(5,132)
    $label_version.Font       = 'Microsoft Sans Serif,9,'
    $label_version.ForeColor  = "#00ff00"
    $label_version.LinkColor  = "#f5a623"
    $label_version.ActiveLinkColor = "#f5a623"
    $label_version.add_Click({[system.Diagnostics.Process]::start("http://github.com/ninthwalker/WoWCDNotifier")})

    # Help link
    $label_help                     = New-Object system.Windows.Forms.LinkLabel
    $label_help.text                = "Get Help (Discord)"
    $label_help.AutoSize            = $true
    $label_help.width               = 80
    $label_help.height              = 30
    $label_help.location            = New-Object System.Drawing.Point(185,132)
    $label_help.Font                = 'Microsoft Sans Serif,9'
    $label_help.ForeColor           = "#00ff00"
    $label_help.LinkColor           = "#f5a623"
    $label_help.ActiveLinkColor     = "#f5a623"
    $label_help.add_Click({[system.Diagnostics.Process]::start("https://discord.gg/m3kG5qbtvy")})

    # debug text
    $label_debug            = New-Object system.Windows.Forms.LinkLabel
    $label_debug.text       = "Debug"
    $label_debug.AutoSize   = $True
    $label_debug.width      = 30
    $label_debug.height     = 20
    $label_debug.location   = New-Object System.Drawing.Point(85,132)
    $label_debug.Font       = 'Microsoft Sans Serif,9,'
    $label_debug.ForeColor  = "#00ff00"
    $label_debug.LinkColor  = "#f5a623"
    $label_debug.ActiveLinkColor = "#f5a623"
    $label_debug.add_Click({
        Start-Debug
        $form.Dispose()
    })

    # add all controls
    $form.Controls.AddRange(($button_install,$button_uninstall,$label_status,$label_version,$label_help,$label_debug))

    # Button methods
    $button_install.Add_Click({Start-WowCdNotifier})
    $button_uninstall.Add_Click({Remove-WoWCdNotifier})

    # show the forms
    $form.ShowDialog()

    # close the forms
    $form.Dispose()
}