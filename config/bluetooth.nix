{ ... }:

{
	# Required for Quickshell.Bluetooth/UPower (home/quickshell/src/services/BluetoothStatusService.qml,
	# modules/BatteryIndicator.qml) to have an adapter/battery to report on.
	hardware.bluetooth.enable = true;
	services.blueman.enable = true;
	services.upower.enable = true;
}
