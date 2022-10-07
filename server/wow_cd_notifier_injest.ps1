# WOTLK Cooldown Alerter
# Author: Ninthwalker
# Last Modified: 06OCT2022
# Used in conjunction with this WA: https://wago.io/sluyr3nQ8
# Instructions:
# Run this as a Windows Scheduled Task
# this should be called from the cdNotifierBot.js but can technically run it outside of that as well
# run it to check peoples alerts every 10min. Code below is set for this 10 min interval. May need to adjust slightly for a buffer window as it could miss if its too exact possibly.
# task arguments: -executionpolicy bypass -noprofile -nologo -windowstyle hidden -File "..\wow_cd_notifier_injest.ps1"
##################################

#####################################
### Do not Modify below this line ###
#####################################

# time
$timeNow = ((Get-Date).ToUniversalTime())

# get csv files
$path = 'file upload path'
$cdInfo = Import-Csv -Path  (Get-ChildItem -Path $path -Filter '*.csv' -File -Recurse).FullName
$script:alertList = @()

function New-Alert {

    Param(
        [String]$title,
        [String]$color,
        [String]$icon,
        [String]$msg,
        [String]$realm,
        [String]$char,
        [String]$link,
        [String]$discordId
    )

    $script:alertList += [PSCustomObject]@{
        title = $title
        color = $color
        icon  = $icon
        msg   = $msg
        realm = $realm
        char = $char
        link = $link
        discordId = $discordId
    }
}


# determine if CD is coming up. Alert if it is less than the $alertTime
foreach ($cd in $cdInfo) {

    # allows the script to continue to alert even after it is off CD. 
    if ($cd.keepBuggingMe) {$bugMe = -1440} else {$bugMe = 0} # 1 days, don't bug them longer than that. lol

    $diff = [datetime]$cd.time - $timeNow
    $localTime = ([datetime]$cd.time).AddHours($cd.timeOffset)

    if ( ($diff.TotalMinutes -ge $bugMe) -and ($diff.TotalMinutes -le $cd.alertTime) ) {
        # Send discord alert. Less than $alertTime until CD is ready! Also need to check if there is no time or its off cd type situation. -UFormat %r if we just want the time and not date. Time is UTC now to use UTC from remote computer.
        # newline also works with: $(0x0A -as [char])
        if ( ($cd.keepBuggingMe -eq $True) -and ($diff -le 0) -and ($cd.interval -eq $True) -and ($diff.TotalMinutes%$cd.intervalTime -ge -10)) {
            New-Alert -discordId $cd.discordId -icon $cd.Icon -title "$($cd.name) Cooldown is ready!" -color "GREEN" -msg "**Time is money, friend!**$(0x0A -as [char])**Was Ready At:** $(Get-Date $localTime -F g)" -link $cd.link -realm $cd.Realm -char $cd.char
        }
        elseif ( ($cd.interval -eq $True) -and ($diff -ge 0) -and ($diff.TotalMinutes -le $cd.alertTime) -and ($diff.TotalMinutes%$cd.intervalTime -le 10) ) {
            New-Alert -discordId $cd.discordId -icon $cd.Icon -title "$($cd.name) Cooldown is almost ready!" -color "YELLOW" -msg "**Cooldown ready in:** $( if($diff.days -gt 0) {"$($diff.days)d "}) $( if($diff.hours -gt 0) {"$($diff.hours)h "}) $( if($diff.minutes -gt 0) {"$($diff.minutes)m"}) $( if(($diff.minutes -le 0) -and ($diff.hours -le 0) -and ($diff.days -le 0)){"$($diff.seconds)s"})$(0x0A -as [char])**Ready At:** $(Get-Date $localTime -F g)" -link $cd.link -realm $cd.Realm -char $cd.char
        }
        elseif (($diff.TotalMinutes -le $cd.alertTime) -and ($diff.TotalMinutes -ge ($cd.alertTime - 10))) {
            New-Alert -discordId $cd.discordId -icon $cd.Icon -title "$($cd.name) Cooldown is almost ready!" -color "YELLOW" -msg "**Cooldown ready in:** $( if($diff.days -gt 0) {"$($diff.days)d "}) $( if($diff.hours -gt 0) {"$($diff.hours)h "}) $( if($diff.minutes -gt 0) {"$($diff.minutes)m"}) $( if(($diff.minutes -le 0) -and ($diff.hours -le 0) -and ($diff.days -le 0)){"$($diff.seconds)s"})$(0x0A -as [char])**Ready At:** $(Get-Date $localTime -F g)" -link $cd.link -realm $cd.Realm -char $cd.char
        }
        else {
            # don't alert
        }
    }
    else {
        # Don't alert yet
    }

}

if ($script:alertList) {
    $script:alertList | Export-Csv ./cdInfoCombined.csv -Force -NoTypeInformation
    $alertMsg =  [psCustomObject] @{'newAlerts' = "yes"}
    $alertMsg | ConvertTo-Json -Compress
}
else {
    $alertMsg =  [psCustomObject] @{'newAlerts' = "no"}
    $alertMsg | ConvertTo-Json -Compress
}