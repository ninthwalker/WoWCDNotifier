<p align="center">
<img align="center" src="https://raw.githubusercontent.com/ninthwalker/github/main/img/wowcdnotifier/wotlk_icon.png" width="250"></p>

# WoW Cooldown Notifier
**WOTLK Classic Cooldown Notifications**  

Sends a discord notification when a crafting cooldown is availble to use.  
Current Cooldowns include: Titansteel, Spellcloth, Brilliant Glass, ..  

## Details/Requirements
1. Windows 10 (version 17063 [April 2018 update]) or higher
2. World of Warcraft w/ WeakAuras Addon
3. Discord

## How it works
This script is utilized in conjunction with a weak aura. The script reads the weak aura cooldown data and uses that for notifications. Pretty simple.
There are 2 versions:  

1. **Client version:**  
This one can be used without you needing to leave your computer on all the time. It will upload the cooldown data to a secure server (similar to TSM or Warcraft Logs desktop clients) that will then notify you when cooldowns are ready.  

2. **Standalone Version.**  
If you don't want to have your data uploaded, then you can run the standalone version. This does however require your computer to be turned on so it can send you the notifications.

## Client Version - Setup Instructions  

I tried to make it as simple as possible, but there are a few steps you need to do to have this work.  

1. Install the [weak auras addon](https://www.curseforge.com/wow/addons/weakauras-2) and then import this cooldown tracker addon here: [https://wago.io/sluyr3nQ8](https://wago.io/sluyr3nQ8)  

2. Join WoW CD Notifier Discord and join the #get-a-token channel. Here you can request a unique token to use for your notifications. You also must stay in this server to allow the bot to be able to direct message you for notifications.
Discord Server Invite link: [https://discord.gg/m3kG5qbtvy](https://discord.gg/m3kG5qbtvy)   

3. Download this Github repo to your computer:  
  a. Click the green 'Code' button on this page. Then select 'Download Zip'. ([Or just click here](https://github.com/ninthwalker/WoWCDNotifier/archive/refs/heads/main.zip))  
  b. You may need to 'unblock' the zip file downloaded. This is normal behavior for Microsoft Windows to do for files downloaded from the internet. `Right click > Properties > Check 'Unblock'`  
  c. Extract the contents of the ZIP file. The files you want are in the 'Client' folder. Make sure these files are kept in the same directory wherever you move them to.  

4. Open up the 'wow_cd_notifier_settings.txt' file and configure. Please read the included sample settings file or see down below in the #settings section. Save the file when completed.  

5. After you have configured the settings file, Double click the 'WoW CD Notifier' shortcut. This will open up a little GUI for you to install the WoW CD Notifier app that will create a scheduled task on your computer. This will check every 30 minutes for new cooldown times to send you Discord notifications when they are ready!  

## Standalone Version - Setup Instructions  

1. Install the [weak auras addon](https://www.curseforge.com/wow/addons/weakauras-2) and then import this cooldown tracker addon here: [https://wago.io/sluyr3nQ8](https://wago.io/sluyr3nQ8)  

2. Download this repo to your computer:  
  a. Click the green 'Code' button on this page. Then select 'Download Zip'. ([Or just click here](https://github.com/ninthwalker/WoWCDNotifier/archive/refs/heads/main.zip))  
  b. You may need to 'unblock' the zip file downloaded. This is normal behavior for Microsoft Windows to do for files downloaded from the internet. `Right click > Properties > Check 'Unblock'`  
  c. Extract the contents of the ZIP file. The files you want are in the 'Standalone' folder. Make sure these files are kept in the same directory wherever you move them to.   
  
3. Create a Discord Webhook for the channel you want to use for notifications.  

4. Open up the 'wow_cd_notifier_settings.txt' file and configure. Please read the included sample settings file or see down below in the #settings section. Save the file when completed.   

5. After you have configured the settings file, Double click the 'WoW CD Notifier' shortcut. This will open up a little GUI for you to install the WoW CD Notifier app that will create a scheduled task on your computer to check every 30 minutes for new cooldown times to send you Discord notifications when they are ready.  

## Uninstall  

1. Doubleclick the 'WoW CD Notifier' shortcut link. Then click the Uninstall button. Too easy!

## Reconfigure

1. If you want to change the settings, you can do so at any time and the next time the scheduled task runs, it will pick up the new settings.  

2. If you want to change the location of the files, move the files to the new location, and then double click the 'WoW CD Notifier' shortcut again from the new location and click the Install button again.


## Settings

Please see the sample file for all settings and descriptions for them here: [Sample Settings File](https://github.com/ninthwalker/WoWCDNotifier/blob/main/client/wow_cd_notifier_settings_sample.txt)  

## FAQ/Common Issues  

1. This code is public and available for review. The Data submitted to the server does not contain any personal information, only the crafting cooldown data and your discordID so we know who to send the notification to. If you have an issue with this, then this app probably is not for you. Or you can use the Standalone version if you have a computer on all the time. That is self-contained and does not upload any data.  

2. If you would like the data that is uploaded (cooldown data and discordID) removed at any time, join the WoW CD Notifier discord and make a request in the #support channel. Discord Invite: [https://discord.gg/m3kG5qbtvy](https://discord.gg/m3kG5qbtvy)  

3. If you have issues running the script on your computer, first make sure it is not blocked since it was downloaded from the internet (see step #2 above). Then if scripts are still blocked, open up powershell on your computer and you can type the following command to allow scripts. Note this does allow all scripts to run in the future for you as well:  
`Set-ExecutionPolicy -Scope Currentuser Bypass`  
 
4. This does not touch or modify World of Warcraft in any way and conforms to all TOS/EULA.  

5. Please put in a github request for any feature requests or if a cooldown you want is not working. Otherwise join us in the discord server for other help. Thanks!  

6. Get additional help in the WoW CD Notifier Discord server: [https://discord.gg/m3kG5qbtvy](https://discord.gg/m3kG5qbtvy)  

## Screenshots & Videos  
<p align="center">
<img align="center" src="https://raw.githubusercontent.com/ninthwalker/github/main/img/wowcdnotifier/wow_cd_notifier_github_img1.png"></p>
