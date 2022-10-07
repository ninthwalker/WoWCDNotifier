//// WoW CD NOTIFIER DISCORD BOT /////
// Author: Ninthwalker
// Last Modified: 06OCT2022
// To be used in conjunction with these dependencies:
//// wow_cd_notifier.ps1 (external user's computer)
//// wow_cd_notifier_injest (on node server)
//// Weak Aura: https://wago.io/sluyr3nQ8 (in-game)

//// INITIATE NODE.JS ////
const auth = require('./auth.json');
const Discord = require('discord.js');
const {Client, Attachment, MessageEmbed} = require('discord.js');
const bot = new Discord.Client();
const Shell = require('node-powershell');
const schedule = require('node-schedule'); 
const csv = require('csv-parser')
const fs = require('fs')

//// DISCORD BOT SECTION /////
bot.login(auth.token);

bot.on('ready', () => {
  console.info(`Logged in as ${bot.user.tag}!`);
  console.info('By your command!');
});


//// DISCORD ALERT SEND SECTION ///
// ie: run every 5min past the hour = 5 * * * *. every 5min = */2 * * * *//
const dmSend = schedule.scheduleJob('*/10 * * * *', function(fireDate){
	console.log('Scheduled run time: ' + fireDate + ', Actual run time: ' + Date());

    ps = new Shell({
        executionPolicy: 'Bypass',
        noProfile: true
    });

    ps.addCommand('./wow_cd_notifier_injest.ps1')
    ps.invoke()
        .then(results => {
            let cdData = JSON.parse(results);

            // run if there are new alerts
			if (cdData.newAlerts == "yes") {
				console.log("New CD's are ready to notify");
				console.log("Reading cdInfo File at " + Date());
				const cdAlertPath = `./cdInfoCombined.csv`
					
				// check if file exists. If not, don't run
				fs.access(cdAlertPath, fs.F_OK, (err) => {
					if (err) {
						console.log("No cdInfoCombined file to alert on")
						ps.dispose()
					}
					else {
					
						// generate alerts and send. send alerts from the generated cdinfo file
						const cdAlert = [];
						fs.createReadStream(cdAlertPath)
						.pipe(csv())
						.on('data', (data) => cdAlert.push(data))
						.on('end', () => {
							
							let cdAlertSize = cdAlert.length
							console.log("Total Alerts to send: " + cdAlertSize);
							
							// set timer for delay
							const timer = ms => new Promise(res => setTimeout(res, ms))
							
							// iterate
							// wrap in async for timer
							async function sendIT() {
								for(let i = 0; i < cdAlertSize; i++){
									let userId = cdAlert[i].discordId
									bot.users.fetch(userId)
									.then(user => {
										const discordResponse = new Discord.MessageEmbed()
											.setColor(cdAlert[i].color)
											.setTitle(cdAlert[i].title)
											.setURL(cdAlert[i].link)
											.setDescription(cdAlert[i].msg)
											.setThumbnail(cdAlert[i].icon)
											.setFooter(`${cdAlert[i].realm} ● ${cdAlert[i].char}`);
										user.send(discordResponse).catch(error => console.error('Permissions Error: ', error))
										console.log(`Sent alert to ${user.username} with msg of: ${cdAlert[i].title}`);
									})
									.catch(user => {
										console.log(user)
										console.log("User not found or something went wrong getting the user from fetch");
									});
									
									await timer(2000);
								};
							};
							// run the send function
							sendIT();
						});
						ps.dispose()	
					};
				});
				ps.dispose()
			}
			else {
				console.log("NO CD's to notify yet");
				ps.dispose()
			}
		})
        .catch(err => {
            console.error(err)
            //reject(err)
            ps.dispose()
        })
});