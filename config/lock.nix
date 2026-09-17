# PAM service for home/quickshell-lock/LockContext.qml's own PamContext
# (config: "syland-lock"). Empty {} inherits NixOS's default PAM
# mechanisms for a service like this -- currently just unix password
# auth, but note that also means any *globally*-enabled mechanism (e.g.
# fprintd, if that's ever turned on system-wide later) would silently
# apply here too, not just password auth.
{ ... }:

{
  security.pam.services.syland-lock = {};
}
