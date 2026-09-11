{ config, ... }:

{
	services.mpd = {
		enable = true;
		musicDirectory = "${config.home.homeDirectory}/media/music";
		extraConfig = ''
			auto_update "yes"

			# MPD was falling back to raw alsa (no mixer control named "PCM",
			# so volume was stuck at n/a) since pipewire-pulse is what actually
			# owns the audio session here. Routing through it gives mpc/rmpc a
			# working software volume and lets MPD share the device with
			# everything else instead of grabbing it exclusively.
			audio_output {
				type "pulse"
				name "pipewire"
			}
		'';
	};

	# Stored playlist MPD reads from its playlist_directory — shows up as
	# "Radio" in rmpc's Playlists tab. Add more stations by appending another
	# #EXTINF/URL pair; no rescan needed, MPD reads this live from disk.
	xdg.dataFile."mpd/playlists/Radio.m3u".text = ''
#EXTM3U
#EXTINF:-1,SomaFM: Groove Salad (ambient/chillout)
https://ice2.somafm.com/groovesalad-128-mp3
#EXTINF:-1,SomaFM: Secret Agent (spy jazz/lounge)
https://ice6.somafm.com/secretagent-128-mp3
#EXTINF:-1,SomaFM: Fluid (deep chill hip-hop)
https://ice5.somafm.com/fluid-128-mp3
#EXTINF:-1,SomaFM: Beat Blender (DJ-mixed electronica)
https://ice6.somafm.com/beatblender-128-mp3
#EXTINF:-1,SomaFM: PopTron (indie electropop)
https://ice6.somafm.com/poptron-128-mp3
#EXTINF:-1,Funk The Planet
https://streaming.live365.com/a01484
'';
}
