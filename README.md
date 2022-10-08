<p align="center">
<img align="center" src="https://raw.githubusercontent.com/ninthwalker/WoWCDNotifier/main/img/wotlk_icon.png" width="250"></p>  
# WoW CD Notifier  
## WOTLK Classic Cooldown Notifications  

Sends a discord notification when a crafting cooldown is availble to use.  
ie: Titansteel, Spellcloth, Brilliant Glass, etc.  

## Details/Requirements
1. Windows 10 (version 17063 [April 2018 update]) or higher
2. Powershell 3.0+ (Comes with WIN10)
3. A World of Warcraft Subscription. (You have to put this on your WIN 10 computer yourself)
4. Discord

## How it works
This script is utilized in conjunction with a weak aura. The script reads the weak aura cooldown data and uses that for notifications. Pretty simple.
There are 2 versions:  

1. Client version:
This one can be used without you needing to leave your computer on all the time. It will upload the cooldown data to a secure server (similar to TSM or Warcraft Logs desktop clients) that will then notify you when cooldowns are ready.  

2. Standalone Version.  
If you don't want to have your data uploaded, then you can run the standalone version. This does however require your computer to be turned on so it can send you the notifications.

## Client Version - Setup Instructions  

I tried to make it as simple as possible, but there are a few steps you need to do to have this work.  

1. Install the [weak auras addon](https://www.curseforge.com/wow/addons/weakauras-2) and then import this cooldown tracker addon here: [](https://wago.io/sluyr3nQ8)  

2. Join WoW CD Notifier Discord and join the #get-a-token channel. Here you can request a unique token to use for your notifications. You also must stay in this server to allow the bot to be able to direct message you for notifications.
Discord Server Invite link: [](https://discord.gg/m3kG5qbtvy)   

3. Download this repo to your computer:  
  a. Click the 'Clone or Download' link on this page. Then select 'Download Zip'  
  b. You may need to 'unblock' the zip file downloaded. This is normal behavior for Microsoft Windows to do for files downloaded from the internet.  
  `Right click > Properties > Check 'Unblock'`  
  c. Extract the contents of the ZIP file. The 2 files you want are in the 'Client' folder. Make sure these 4 files are kept in the same directory wherever you move them to.  

4. Open up the settings.txt file and configure as noted in the settings file or see down below in the #settings section. Save the file when completed.  

5. After you have configured the settings.txt file, Double click the 'Setup WoW CD Notifier' shortcut. This will create a scheduled task on your computer that will run once an hour to upload the cooldown data for notifications.  

6. That's it!  
If everything is set up correctly, then you will start to receive a discord direct message from the bot according to your cooldowns and the settings you configured.

## Standalone Version - Setup Instructions  

1. Install the [weak auras addon](https://www.curseforge.com/wow/addons/weakauras-2) and then import this cooldown tracker addon here: [](https://wago.io/sluyr3nQ8)  

2. Create a Discord Webhook for the channel you want to use for notifications.  

3. Open up the settings.txt file and configure as noted in the settings file or see down below in the #settings section. Save the file when completed.  

5. After you have configured the settings.txt file, Double click the 'Setup WoW CD Notifier - Standalone' shortcut. This will create a scheduled task on your computer that will send you a discord message when your cooldows are ready.  

## FAQ/Common Issues  
1. This code is public and available for review. The Data submitted to the server does not contain any personal information, only the crafting cooldown data and your discordID so we know who to send the notification to. If you have an issue with this, then this app probably is not for you. Or you can use the Standalone version if you have a computer on all the time. That is self-contained and does not upload any data.  

2. If you would like the data that is uploaded (cooldown data and discordID) removed at any time, join the WoW CD Notifier discord and make a request in the #support channel. Discord Invite: [](https://discord.gg/m3kG5qbtvy)  
 
3. This does not touch or modify World of Warcraft in any way and conforms to all TOS/EULA.

## Screenshots & Videos  
coming soon
