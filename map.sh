#!/bin/bash


#screen names:
sc_map='map';				#not used at this point ***but it's implemented
sc_minecraft="MineCraft"
sc_RUN="BackupProcess"

PUBLIC_URL="http://map.infocorp.hu"

#MineCraft installation varriables:
map_name="NorthCraft"
map_folder_location="/srv/minecraft";

#overviewer config files locations
ov_config="/srv/minecraft_ov/new_config.cfg";

#temp_location
TEMP_DIR="/srv/minecraft_temp/";

#Backup Location:
BACKUP_DIR="/srv/minecraft_backups/"
BACKUP_NAME="minecraft_save_$(date +%F_%H-%M).tar.gz"





## SharedVars:
sc_RUN_exist=-1
sc_minecraft_exist=-1
sc_map_exist=-1


status_copy=-1
status_save=-1



#Copy File Functions:
function make_copy()
{

SourceFolder="$map_folder_location/$map_name"
DestFolder=$TEMP_DIR

if [ ! -w "$DestFolder" ]
    then
        # Not writable. Pop the error and exit.
        echo "Directory $dnam is not writable"
        status_copy=1
	else
		#ELSE make a copy 
		cp -r $SourceFolder $DestFolder
		status_copy=0
	fi
}



#Check Screens:
	function ch_RUN_SC ()
	{


	if ! screen -list | grep -q $sc_RUN
	then
		sc_RUN_exist=0
	else
		sc_RUN_exist=1
	fi
	  
	}
	function ch_screen_map ()
	{


	if ! screen -list | grep -q $sc_map
	then
		sc_map_exist=0
	else
		sc_map_exist=1
	fi
	  
	}

	function ch_screen_minecraft ()
	{


	if ! screen -list | grep -q $sc_minecraft
	then
		sc_minecraft_exist=0
	else
		sc_minecraft_exist=1
	fi
	  
}
function chk_sc ()
{

			if [ "$sc_RUN_exist" == "0" ];then
					echo -e "\e[31mScreen check is FAIL\e[39m"
					echo -e "\e[31mWARNING, \e[39mMap renderer can take while..  "
					echo -e "\e[31mPLEASE RUN THIS SCRIPT FROM SCREEN TO PREVENT FAILS \e[39m"
					echo "RUN screen: $sc_RUN_exist";
					echo "MineCraft Screen: $sc_minecraft_exist"
					echo -e "\e[32mUse: screen -S $sc_RUN \e[39m"
					exit 1
				else
					echo -e "\e[32mScreen check is pass\e[39m"
			fi
}
function START_ROUTINE ()
{
	#Announce players
	screen -S $sc_minecraft -p 0 -X stuff "say §4§lBackup: §eStarting.^M"
}
function STOP_ROUTINE ()
{
	#Announce players:
	screen -S $sc_minecraft -p 0 -X stuff "say §4§lBackup: §aEVERYTHING §aREADY. ^M"
}

function MAP_ROUTINE ()
{
	#Announce players:
	screen -S $sc_minecraft -p 0 -X stuff "me §3World §3map: §eStarting.^M"
	overviewer.py --config=$ov_config
	wait
	#Announce players:
	screen -S $sc_minecraft -p 0 -X stuff "me §3World §3map: §eFinished.^M"
	screen -S $sc_minecraft -p 0 -X stuff "me map can be view at: §3$PUBLIC_URL ^M"
}
function BACKUP_ROUTINE ()
{
	screen -S $sc_minecraft -p 0 -X stuff "me Generate Archive file wait this name: $BACKUP_NAME^M"
	tar cpvzf  $BACKUP_DIR/$BACKUP_NAME $TEMP_DIR/*  --remove-files
	screen -S $sc_minecraft -p 0 -X stuff "me Archive ready / temp files cleaned up ^M"
}
function COPY_FILE_ROUTINE ()
{
	screen -S $sc_minecraft -p 0 -X stuff "me World Save: §4Off ^M"
	#turn off map save
	screen -S $sc_minecraft -p 0 -X stuff "save-off^M"
	wait
	#force save on map
	screen -S $sc_minecraft -p 0 -X stuff "save-all^M"
	wait
	#copy map to temp dir
	make_copy
	if [ "$status_copy" == "0" ];then
		echo "Copy ready"
		screen -S $sc_minecraft -p 0 -X stuff "me §4§lBackup: §3Map §3Copy: §aReady. ^M"
		wait
	else
		echo "ERROR IN THE COPY"
		screen -S $sc_minecraft -p 0 -X stuff "me §4§lBackup-FAIL. ^M"
		exit 1
	fi
	#turn on world save:
	screen -S $sc_minecraft -p 0 -X stuff "save-on^M"
	screen -S $sc_minecraft -p 0 -X stuff "me World Save: §aOn ^M"
		

}

function helper ()
{
			#run map renderer from temp dir

			echo "Y - Renderer new map, and make backup."
			echo "N - skip renderer process and continue whit backup"
			echo -e "S - Open new screen and start the rendering there \e[33m( This will skip backup ) \e[39m."
			echo -e "F - Force renderer mode \e[33m( This will skip backup ) \e[39m."
			echo -e "G - GenPoi Mode \e[33m( This will skip backup ) \e[39m."
			echo "X - Exit"
}


#The main Logic gate
function runme ()
{


	ch_RUN_SC
	ch_screen_minecraft

	

	if [ "$sc_minecraft_exist" == "0" ]; then
			echo "MineCraft screen offscreen mode not allowed yet"
			exit 1
			
		else
			chk_sc
			helper
			read -p "Do you wish to continue?" answer
				case ${answer:0:1} in
				
					y|Y )
						START_ROUTINE
						COPY_FILE_ROUTINE
						MAP_ROUTINE
						BACKUP_ROUTINE
						STOP_ROUTINE
					;;
					n|N )
						START_ROUTINE
						COPY_FILE_ROUTINE
						BACKUP_ROUTINE
						STOP_ROUTINE
					;;
					s|S )
						COPY_FILE_ROUTINE
						if [ "$sc_map_exist" == "0" ]; then
							echo "map_renderer screen not exists opening new"
							screen -h 2048 -L -dmS "$sc_map"
							screen -S $sc_map -p 0 -X stuff "overviewer.py --config=$ov_config ^M"
							wait
							echo "Script run in background, good by!"
						fi
					;;
					f|F )
						COPY_FILE_ROUTINE
						overviewer.py --force --config=$ov_config
						
					;;
					g|G )
						COPY_FILE_ROUTINE
						overviewer.py --config=$ov_config --genpoi
					;;
					x|X )
						echo "script will exit now..."
						exit 0
					;;
					*)
						echo "Usage:"
						helper
						exit 1
				esac
	fi
	
}
runme


