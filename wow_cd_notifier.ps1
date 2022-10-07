####################### WoW Cooldown Notifier ##########################
# Name: WoW Cooldown Notifier                                          #
# Desc: Sends Discord Notifications when your WoW Crafting Cooldown up #
# Author: Ninthwalker                                                  #
# Instructions: https://github.com/ninthwalker/WoWCDNotifier           #
# Date: 06OCT2022                                                      #
# Version: 1.1                                                         #
########################################################################

############################ CHANGE LOG ################################
## 1.0                                                                 #
# Initial App release                                                  #
## 1.1                                                                 #
# Add windows notifications for some events when run manually          #
# Refactor mappings                                                    #
########################################################################
 
########################## NOTES FOR USER ##############################
# Used in conjunction with this WA: https://wago.io/sluyr3nQ8          #
# Join the WoW CD Notifier discord: https://discord.gg/m3kG5qbtvy      #
# Please follow directions on the githib site!                         #
# What this does:                                                      #
# Creates a scheduled task on your computer that will upload your wow  #
#  cooldown information to a secure server to process                  #
# This information can then be used to send you an alert in discord    #
#  when your cooldown is ready even when your computer is not on.      #
# Additional Info:                                                     #
# If making the task manually make sure to name the task exactly       #
# "WoW CD Notifier" since this script will check for that name.        #
# Task Arguments: -executionpolicy bypass -noprofile -nologo           #
# -windowstyle hidden                                                  #
# -File "C:\your_file_path_to-script_here\wow_cd_notifier.ps1"         #
# Also 'run whether user is logged in or not' to prevent ps flash      #
########################################################################

########################################################################
#########             Enter your settings below                #########
########################################################################

# Enter the full path to the WeakAuras.lua file on your computer
# normally under: ..\World of Warcraft\_classic_\WTF\Account\<ACCOUNT_NAME>\SavedVariables\WeakAuras.lua"
$waLuaPath = "your weak aura lua path here"

# Enter in the realm name(s) to check. Add more with a comma and the next name in quotes. ie: ("Whitemane,"Skyfury","etc")
$realmNames = ("your server name")

# Enter in the character name(s) to check for cooldowns
# Only enter each character name once. ie: if you have a character named 'Joe' on realm1 and realm2 to check, only list 'Joe' once below.
# ie for one char: ("SliceAndDice")
# ie for multiple char's: ("SliceAndDice","MySecondToon", "ImAnAltaholic") 
$charNames = ("your char name(s)")

# Discord
# Set your discord ID (not username) so the bot can DM you when your CD is ready according to your alert settings below
# ie: "364629917848719580". You can get this yourself from your discord client, or when you request a token in the WoW CD Notifier discord server, it can be given to you then.
$discordId = "your discord id"

# Upload file key. Unique for each user. Request one from the discord server: https://discord.gg/m3kG5qbtvy
$token = "your unique key here"

# Enter time (in minutes) for how far before your CD is ready to start alerting you.
# defailt is to alert 3 hrs before your CD is ready (180 min)
$alertTime = 180

# Interval
# how often do you want to keep bing alerted? Setting this to $True will keep alerting you every $intervalTime (in minutes, lowest value is 10, and maximum would be the $alertTime you set above)
# ie: if $alertTime is set to 180 (3hrs) and you set this to 60, you would receive an alert 3hrs before, then every hour after.
# set interval to $True to enable or $False to only alert once when the $alertTime is met.
# default is $False
$interval = $False
$intervalTime = 60

# Continous alerting. Set $keepBuggingMe to $True if you want an alert every set $intervalTime even after your cooldown is ready. Will keep bugging you for each interval up to one day past it's CD.
# this requires that $interval is set above to $True
# default is $False
$keepBuggingMe = $False

########################################################################
########            Do not Modify anything below this          #########
########################################################################


# path of this script
$scriptPath = $MyInvocation.MyCommand.Path

# Functions
# create scheduled task if it does not exist
# uses this code to create the task for you. Using WScript.Shell and mshta to prevent ps window from showing. Other methods woudl require additional user input that is not as user friendly as this.
Function New-CdTask {
    $taskInterval = (New-TimeSpan -Minutes 60)
    $taskTrigger = New-ScheduledTaskTrigger -Once -At 00:00 -RepetitionInterval $taskInterval
    #$taskUser = (Get-CimInstance -ClassName Win32_ComputerSystem).Username
    #$creds = Get-Credential -Credential $taskUser #use this if the default task action below does not work
    #$taskPass = $creds.GetNetworkCredential().Password #use this if the default task action below does not work
    #$taskAction = New-ScheduledTaskAction -Execute powershell.exe -Argument -executionpolicy bypass -noprofile -nologo -windowstyle hidden -File $scriptPath #use this if the default task action below does not work
    $taskAction = New-ScheduledTaskAction -Execute 'mshta' -Argument $taskArgs
    $taskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -StartWhenAvailable -DontStopIfGoingOnBatteries
    Register-ScheduledTask -TaskName $taskName -Action $taskAction -Trigger $taskTrigger -Settings $taskSettings -Description "Sends a discord alert for WoW Profession Cooldowns"
}

#toast notifications - only shown when this is run manually or from shortcut to help with debugging/status
Function New-PopUp {

    param (
        [string]$msg,
        [string]$icon
    )

    [reflection.assembly]::loadwithpartialname('System.Windows.Forms') | Out-Null
    $notify = new-object system.windows.forms.notifyicon
    $notify.BalloonTipTitle = "WoW CD Notifier"
    $notify.icon = [System.Drawing.SystemIcons]::Information
    $notify.visible = $true
    $notify.showballoontip(10,'WoW CD Notifier',$msg,[system.windows.forms.tooltipicon]::$icon)
}

$taskName = "WoW CD Notifier"
$taskArgs =  @"
vbscript:Execute("CreateObject(""WScript.Shell"").Run ""powershell -ExecutionPolicy Bypass & '$scriptPath'"", 0:close")
"@

Function New-Check {
    try {
        $script:task = (get-ScheduledTask -TaskName $taskName -ErrorAction Stop).actions.arguments
        $script:checkTask = $True
    }
    catch {
        $script:checkTask = $False
    }
}

# check if running from task scheduler to not use toast notifications
$proc = (Get-Process -Id (Get-CimInstance Win32_Process -Filter "ProcessID = $pid").ParentProcessId).Name
if ( ($proc -eq 'explorer') -or ($proc -eq 'powershell') ) {
    $canToast = $True
}

# save path
$path = "$env:TEMP\cdInfo.csv"

#check task
New-Check
if ($checkTask) {
    
    if ($task -notlike "*$scriptPath*") {
        # task path is bad, delete and re-create
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        Start-Sleep -Seconds 1
        New-CdTask
        Start-Sleep -Seconds 1
        New-Check
        if ($checkTask -and $canToast) {New-PopUp -msg "Setup completed successfully. Have fun!" -icon "Info"}
        else {
            if ($canToast) {New-PopUp -msg "Setup FAILED! Join the discord for help" -icon "Warning"}
        }

    }
    else {
        # already configured correctly
        if ($canToast) {New-PopUp -msg "Setup was already completed. Have fun!" -icon "Info"}
    }
}
else {
    New-CdTask
    Start-Sleep -Seconds 1
    New-Check
    Start-Sleep -Seconds 1
    if ($checkTask -and $canToast) {New-PopUp -msg "Setup completed successfully. Have fun!" -icon "Info"}
    else {
        if ($canToast) {New-PopUp -msg "Setup FAILED! Join the discord for help" -icon "Warning"}
    }
}

#only run the rest of code if the file has changed since our last upload
Try {
    $lastFileUpdate = (Get-Item $waLuaPath -ErrorAction Stop).LastWriteTime
    $lastUpload = (Get-Item $path).LastWriteTime
}
Catch {
    if ($canToast) {New-PopUp -msg "Issue with weakauras file. Check that addon is installed and WA path is correct " -icon "Warning"}
}
if ($lastFileUpdate -eq $lastUpload) {
    # no reason to upload
    if ($canToast) {
        New-PopUp -msg "Cooldown Data was already uploaded. Nothing new" -icon "Info"
        Return
    }
}

# cd mappings
$cooldownName = @('Spellcloth','Shadowcloth','Primal Mooncloth','Primal Might','Brilliant Glass','Ebonweave','Moonshroud','Spellweave','Titansteel')
$cooldownID = @(31373,36686,26751,29688,47280,56002,56001,56003,55208)
$cooldownIcon =@('inv_fabric_spellfire.jp','inv_fabric_felcloth_ebon.jpg','inv_fabric_moonrag_primal.jpg','spell_nature_lightningoverload.jpg', `
'inv_misc_gem_diamond_03.jpg','inv_fabric_ebonweave.jpg','inv_fabric_moonshroud.jpg','inv_fabric_spellweave.jpg','inv_ingot_titansteel_blue.jpg')

$baseUrl = "https://render.worldofwarcraft.com/us/icons/56/"
$map = for ($i = 0; $i -lt $cooldownName.count; $i++) {
    [pscustomobject]@{
        ID = $cooldownID[$i]
        Name = $cooldownName[$i]
        Icon = $baseUrl + $cooldownIcon[$i]
    }
}

# wa data
$waData = Get-Content -Raw $waLuaPath
$cdInfo = @()
$charNames = $charNames | select -Unique

foreach ($server in $realmNames) {

    foreach ($toon in $charNames) {

        foreach ($ID in $cooldownID) {

            # regex to match on ID and expiration date (which is when it's CD is up) It's in epoch time
            # Its the expiration
            # start with getting the correct realm and character
            $filter = $waData -match '(?smi)(?<=cooldownsDb.*' + $server + '.*' + $toon + '.*' + $ID + '.*expiration\"\]\ = ).*?(\d+\.?\d+)'
            if ($filter) {
                $mapMatch = $map | ? {$_.ID -eq $ID}
                # add expiration info into PS object
                $cdInfo += [psCustomObject]@{
                    'name' = $mapMatch.Name
                    'id'   = $ID
                    'time' = ([datetimeoffset]::FromUnixTimeSeconds($matches[0])).UtcDateTime
                    'realm' = $server
                    'char' = $toon
                    'icon' = $mapMatch.Icon
                    'link' = "https://www.wowhead.com/spell=" + $ID
                    'alertTime' = $alertTime
                    'interval' = $interval
                    'intervalTime' = $intervalTime
                    'keepBuggingMe' = $keepBuggingMe
                    'discordId' = $discordId
                    'timeOffset' = ([datetimeoffset]::now).Offset.Hours
                }
            }
        }
    } 
}

if ($cdInfo) {
    # export
    $cdInfo | Export-Csv -Path $path -Force -NoTypeInformation

    # upload
    # needs pwsh to use -Form. Otherwise use curl.exe which was included with win 10 version 17063 (April 2018 update)
    #$form = @{
    #    data = Get-Item -Path $path
    #}
    #$upload = Invoke-WebRequest -Uri wowcd.ninthwalker.app/upload?key=$token -Method Post -Form $form
    $upload = curl.exe --silent -XPOST -F "data=@$path" https://wowcd.ninthwalker.app/upload?key=$token
    # update modtime to use for existing checks
    if ($upload -eq "Upload successful") {
        $lastFileUpdate = (Get-Item $waLuaPath).LastWriteTime
        (Get-Item $path).LastWriteTime = $lastFileUpdate
    }
    else {
        if ($canToast) {New-PopUp -msg "Upload FAILED! Join the discord for help. Error: $upload" -icon "Warning"}
    }
}
