# Replaces the earlier greetd-based greeter entirely (see git history /
# the plan doc for that approach) — autologin straight into tesdap's own
# real Hyprland session, immediately locked (home/quickshell-lock/, the
# same session lock built for idle/manual locking), instead of a
# separate throwaway-compositor greeter session that then has to tear
# itself down before the real one can start. Confirmed live that the
# greetd handoff had an unavoidable "bare compositor, config still
# loading" gap — sequential session teardown-then-start, since only one
# compositor can hold the GPU/DRM device at a time. Autologin removes the
# handoff entirely: one continuous session from boot, with the lock
# engaging as the very first thing home/hypr/base.lua's own startup hook
# does (before awww/qs/mako even start), so by the time you unlock, the
# desktop is already fully painted behind it.
#
# Real security-model difference from greetd, not just an implementation
# detail: home/hypr/base.lua/home/shell.nix's own exec-Hyprland-on-tty1
# hook and this session's daemons run as tesdap *before* the lock has
# been typed past, not after authentication gates the session start at
# all. Locked the whole time, nothing exposed if the lock genuinely
# engages first — but worth remembering this trades "authenticate before
# anything starts" for "authenticate before anything's visible", a
# reasonable tradeoff on a personal single-user machine where physical
# possession is already the real trust boundary, not the same tradeoff
# on a shared/multi-user machine.
#
# autologinOnce, not just autologinUser alone: without it, NixOS's own
# getty module autologins *every* tty as tesdap (confirmed via its own
# docs), turning every virtual terminal into a passwordless shell, not
# just tty1 once at boot.
{ ... }:

{
  services.getty.autologinUser = "tesdap";
  services.getty.autologinOnce = true;
}
