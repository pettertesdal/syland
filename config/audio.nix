{ ... }:

{
	# The Arctis Nova Pro Wireless dongle and some other unrelated USB
	# Audio device (both generic ALSA cards) end up at the same default
	# WirePlumber priority (1109), so which one wins as the default
	# sink/source is a coin flip on connect. Force the Arctis higher so
	# it's always preferred when present.
	services.pipewire.wireplumber.extraConfig."51-arctis-default" = {
		"monitor.alsa.rules" = [
			{
				matches = [
					{ "node.name" = "~alsa_(input|output)\\.usb-SteelSeries_Arctis_Nova_Pro_Wireless.*"; }
				];
				actions = {
					update-props = {
						"priority.session" = 2000;
						"priority.driver" = 2000;
					};
				};
			}
		];
	};
}
