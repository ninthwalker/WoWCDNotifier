####################### WoW Cooldown Notifier ##########################
# Name: WoW Cooldown Notifier - Standalone Version                     #
# Desc: Sends Discord Notifications when WoW Crafting Cooldowns are up #
# Author: Ninthwalker                                                  #
# Instructions: https://github.com/ninthwalker/WoWCDNotifier           #
# Date: 12OCT2022                                                      #
# Version: 1.4                                                         #
########################################################################

########################### CHANGE LOG #################################
## 1.4                                                                 #
# Updated wotlk spell cooldowns and WA addon naming convention         #
# Fixed Change log order                                               #
## 1.3                                                                 #
# use winform for more user friendliness. I'm such a nice guy!         #
## 1.2                                                                 #
# Use settings file, I think it is easier for the end user             #
## 1.1                                                                 #
# Add windows notifications for some events when run manually          #
# Refactor mappings                                                    #
## 1.0                                                                 #
# Initial App release                                                  #
########################################################################
 
######################### NOTES FOR USER ###############################
# Used with wow_cd_notifier_standalone_settings.txt                    #
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
if (!$runFromTask) {$canToast = $True}

# get current time
$timeNow = ((Get-Date).ToUniversalTime())

# script version
$version = "v1.4"

# paths of this script
$scriptDir = $PSScriptRoot
$scriptPath = $PSCommandPath
if (!$scriptDir) {$scriptDir = (Get-Location).path}
if (!$scriptPath) {($scriptPath = "$(Get-Location)\wow_cd_notifier_standalone.ps1")}
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

# discord
function Send-Discord {

    Param(
        [String]$title,
        [String]$color,
        [String]$icon,
        [String]$msg,
        [String]$footer,
        [String]$link,
        [String]$discordWebhook
    )

    #Create embed object, also adding thumbnail
    
    $embedObject = [PSCustomObject]@{
        embeds = @([ordered]@{
            title       = $title
            description = $msg
            color       = $color
            url         = $link
            footer      = @{ text = $footer} 
            thumbnail   = @{ url = $icon }
        })
        
    } | ConvertTo-Json -Depth 4

    #Send over payload, converting it to JSON
    Invoke-RestMethod -Uri $discordWebhook -Body $embedObject -Method Post -ContentType 'application/json'
}

Function Start-Debug {
    #start powershell {& $scriptPath -noprofile -noexit -ExecutionPolicy Bypass}
    $argList = "-noprofile -noexit -ExecutionPolicy Bypass -file `"$scriptPath`""
    Start-Process powershell -argumentlist $argList
}

# wowcdnotifier funcion
Function Start-WowCdNotifier {

    if ($canToast) {
        # Disable buttons and clear status
        $button_install.Enabled = $False
        $label_status.ForeColor = "#ffff00"
        $label_status.text = "Installing .."
        $label_status.Refresh()
        Start-Sleep -Seconds 1
    }

    # create scheduled task if it does not exist
    # uses this code to create the task for you:
    Function New-CdTask {
        if ($set.interval -eq $True) {
            $taskIntervalTime = $set.intervalTime
        } else {
            $taskIntervalTime = $set.alertTime
        }
        $taskInterval = (New-TimeSpan -Minutes $taskIntervalTime)
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

    if (Test-Path $scriptDir\wow_cd_notifier_standalone_settings.txt) {
        $set = Get-Settings $scriptDir\wow_cd_notifier_standalone_settings.txt
    } else {
        if ($canToast) {
            New-PopUp -msg "Couldn't find settings file. Please check settings!" -icon "Warning"
            $label_status.ForeColor = "#ffff00"
            $label_status.text = "Couldn't find settings file.`r`nPlease Check settings and try again."
            $label_status.Refresh()
            $button_install.Enabled = $True
        }
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
    $cooldownName = @('Alchemy Transmute','Northrend Alchemy Research','Void Sphere','Brilliant Glass','Icy Prism','Ebonweave','Moonshroud','Spellweave','Glacial Bag','Titansteel','Minor Inscription Research','Northrend Inscription Research')
    $cooldownID   = @(54020,60893,28028,47280,62242,56002,56001,56003,56005,55208,61288,61177)
    $cooldownIcon = @('spell_shadow_manaburn.jpg','trade_alchemy.jpg','inv_enchant_voidsphere.jpg','inv_misc_gem_diamond_03.jpg','inv_misc_gem_diamond_02.jpg','inv_fabric_ebonweave.jpg','inv_fabric_moonshroud.jpg','inv_fabric_spellweave.jpg','inv_misc_bag_enchantedrunecloth.jpg','inv_ingot_titansteel_blue.jpg','inv_inscription_tradeskill01.jpg','inv_inscription_tradeskill01.jpg')
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
                $filterServer = $waData -match '(?smi)(?<=\[\"WoWCDNotifier\"\].*?)(' + $server + '.*?' + $toon + '.*?' + $ID + '.*?expiration).*?(\d+\.?\d+)'
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
                            'discordWebhook' = $set.discordWebhook
                            'timeOffset' = ([datetimeoffset]::now).Offset.Hours
                        }
                    }
                }
            }
        } 
    }

    if ($cdInfo) {

        # determine if CD is coming up. Alert if it is less than the $alertTime
        foreach ($cd in $cdInfo) {

            # rate limit
            Start-Sleep -Seconds 1
            # allows the script to continue to alert even after it is off CD. 
            if ($cd.keepBuggingMe) {$bugMe = -1440} else {$bugMe = 0} # 1 days, don't bug them longer than that. lol

            $diff = [datetime]$cd.time - $timeNow
            $localTime = ([datetime]$cd.time).AddHours($cd.timeOffset)

            if ( ($diff.TotalMinutes -ge $bugMe) -and ($diff.TotalMinutes -le $cd.alertTime) ) {
                # Send discord alert. Less than $alertTime until CD is ready! Also need to check if there is no time or its off cd type situation. -UFormat %r if we just want the time and not date. Time is UTC now to use UTC from remote computer.
                # newline also works with: $(0x0A -as [char])
                if ( ($cd.keepBuggingMe -eq $True) -and ($diff -le 0) -and ($cd.interval -eq $True) ) {
                    Send-Discord -discordWebhook $set.discordWebhook -icon $cd.Icon -title "$($cd.name) Cooldown is ready!" -color "3066993" -msg "**Time is money, friend!** `
                    **Was Ready At:** $(Get-Date $localTime -F g)" -link $cd.link -footer "$($cd.Realm) | $($cd.char)"
                }
                elseif ( ($cd.interval -eq $True) -and ($diff -ge 0) -and ($diff.TotalMinutes -le $cd.alertTime) ) {
                    Send-Discord -discordWebhook $set.discordWebhook -icon $cd.Icon -title "$($cd.name) Cooldown is almost ready!" -color "16776960" -msg "**Cooldown ready in:** $( if($diff.days -gt 0) {"$($diff.days)d "}) $( if($diff.hours -gt 0) {"$($diff.hours)h "}) $( if($diff.minutes -gt 0) {"$($diff.minutes)m"}) $( if(($diff.minutes -le 0) -and ($diff.hours -le 0) -and ($diff.days -le 0)){"$($diff.seconds)s"}) `
                    **Ready At:** $(Get-Date $localTime -F g)" -link $cd.link -footer "$($cd.Realm) | $($cd.char)"
                }
                elseif ($diff.TotalMinutes -le $cd.alertTime) {
                    Send-Discord -discordWebhook $set.discordWebhook -icon $cd.Icon -title "$($cd.name) Cooldown is almost ready!" -color "16776960" -msg "**Cooldown ready in:** $( if($diff.days -gt 0) {"$($diff.days)d "}) $( if($diff.hours -gt 0) {"$($diff.hours)h "}) $( if($diff.minutes -gt 0) {"$($diff.minutes)m"}) $( if(($diff.minutes -le 0) -and ($diff.hours -le 0) -and ($diff.days -le 0)){"$($diff.seconds)s"}) `
                    **Ready At:** $(Get-Date $localTime -F g)" -link $cd.link -footer "$($cd.Realm) | $($cd.char)"
                }
                else {
                    # don't alert
                }
            }
            else {
                # Don't alert yet
            }

        }
    }
}
# run it if from task
if ($runFromTask) {Start-WowCdNotifier}

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
    Add-Type -AssemblyName System.Windows.Forms, PresentationFramework, PresentationCore, WindowsBase, System.Drawing
    [System.Windows.Forms.Application]::EnableVisualStyles()

    # built-in wotlk logo
    $WotlkLogoBase64Img = "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"
    $WotlkIconBase64Img = "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"

    # decode base64 images
    function DecodeBase64Image {
        param ([Parameter(Mandatory=$true)][String]$ImageBase64)
        $ObjBitmapImage = New-Object System.Windows.Media.Imaging.BitmapImage #Provides a specialized BitmapSource that is optimized for loading images using Extensible Application Markup Language (XAML).
        $ObjBitmapImage.BeginInit() #Signals the start of the BitmapImage initialization.
        $ObjBitmapImage.StreamSource = [System.IO.MemoryStream][System.Convert]::FromBase64String($ImageBase64) #Creates a stream whose backing store is memory.
        $ObjBitmapImage.EndInit() #Signals the end of the BitmapImage initialization.
        $ObjBitmapImage.Freeze() #Makes the current object unmodifiable and sets its IsFrozen property to true.
        $ObjBitmapImage
    }

    #images
    $wotlkImgDecoded = DecodeBase64Image -ImageBase64 $WotlkLogoBase64Img
    $logo = [System.Drawing.Bitmap][System.Drawing.Image]::FromStream($wotlkImgDecoded.StreamSource)

    # built-in Icon
    $iconBase64      = $WotlkIconBase64Img
    $iconBytes       = [Convert]::FromBase64String($IconBase64)
    $stream          = New-Object IO.MemoryStream($iconBytes, 0, $iconBytes.Length)
    $stream.Write($iconBytes, 0, $iconBytes.Length);

    # main form
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
    $form.Icon                      = [System.Drawing.Icon]::FromHandle((New-Object System.Drawing.Bitmap -Argument $stream).GetHIcon())

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
    $label_version.text       = $version
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

    $pictureBox_logo                 = New-Object system.Windows.Forms.PictureBox
    $pictureBox_logo.width           = 80
    $pictureBox_logo.height          = 80
    $pictureBox_logo.location        = New-Object System.Drawing.Point(20,16)
    $pictureBox_logo.image           = $logo
    $pictureBox_logo.SizeMode        = [System.Windows.Forms.PictureBoxSizeMode]::normal

    # add all controls
    $form.Controls.AddRange(($button_install,$button_uninstall,$label_status,$label_version,$label_help,$label_debug,$pictureBox_logo))

    # Button methods
    $button_install.Add_Click({Start-WowCdNotifier})
    $button_uninstall.Add_Click({Remove-WoWCdNotifier})
    $label_debug.add_Click({
        Start-Debug
        $form.Dispose()
    })

    # show the forms
    $form.ShowDialog()

    # close the forms
    $form.Dispose()
}
