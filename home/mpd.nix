{ config, pkgs, ... }:

{
  # MPD doesn't speak MPRIS natively — services/MprisService.qml (in the
  # quickshell config) only ever sees standard MPRIS players, so without
  # this bridge rmpc/mpc playback is invisible to the music widget
  # entirely. mpdris2-rs over mpdris2 (the original Python one): a single
  # static binary, no python/gobject/dbus-python dependency chain to
  # drag in for what's a small background daemon. -n disables its own
  # libnotify notifications — this shell already has its own notification
  # system (services/NotificationService.qml), and two separate "now
  # playing" toasts firing per track change would just be noise.
  systemd.user.services.mpdris2 = {
    Unit = {
      Description = "MPRIS2 bridge for MPD";
      After = [ "mpd.service" ];
      PartOf = [ "mpd.service" ];
    };
    Install.WantedBy = [ "default.target" ];
    Service = {
      ExecStart = "${pkgs.mpdris2-rs}/bin/mpdris2-rs -n";
      Restart = "on-failure";
    };
  };

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
    #EXTINF:-1,Radio Future Funk
    https://stream.zeno.fm/48533y95cnruv
    #EXTINF:-1,Listen.Moe JPop Vorbis
    https://www.allradio.net/widget/12296
  '';
}
