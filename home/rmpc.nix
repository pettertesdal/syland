{ config, pkgs, ... }:

{
	programs.rmpc = {
		enable = true;
		config = ''
			#![enable(implicit_some)]
			#![enable(unwrap_newtypes)]
			#![enable(unwrap_variant_newtypes)]
			(
				on_song_change: ["${config.home.homeDirectory}/.config/rmpc/notify"],
			)
		'';
	};

	xdg.configFile."rmpc/notify" = {
		executable = true;
		# rmpc exports song metadata ($ARTIST/$TITLE/etc.) as env vars to
		# on_song_change hooks. This just feeds them to notify-send, which
		# the quickshell NotificationService/NotificationToast already renders.
		#
		# Radio streams have no separate Artist tag (Icecast/SHOUTcast send
		# one combined "Artist - Song" string as Title, so $ARTIST is empty)
		# and no embedded album art for `rmpc albumart` to extract, so both
		# are handled as an explicit fallback rather than printing
		# "Unknown artist - ..." or a wrong cover.
		text = ''
#!/usr/bin/env sh
cover="/tmp/rmpc/notify-cover"
fallback_icon="${pkgs.adwaita-icon-theme}/share/icons/Adwaita/scalable/mimetypes/audio-x-generic.svg"
mkdir -p "$(dirname "$cover")"
if ! rmpc albumart --output "$cover"; then
	cover="$fallback_icon"
fi
if [ -n "$ARTIST" ]; then
	body="$ARTIST - $TITLE"
else
	body="$TITLE"
fi
notify-send -i "$cover" "Now playing" "$body"
'';
	};
}
