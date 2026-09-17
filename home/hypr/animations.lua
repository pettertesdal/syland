-- Hyprland's own layer-surface fade/slide, separate from anything
-- quickshell's own QML does internally -- confirmed live via
-- `hyprctl animations` that layersIn/layersOut were unconfigured
-- (overriden: 0) and so running on Hyprland's default curve, which was
-- masking/competing with TodoPanel's own settle motion and border-flash
-- animation. layerrules.lua's existing per-namespace
-- `no_anim = true` may or may not be the correct hl.layer_rule property
-- name for this (unverified, same class of uncertainty flagged
-- elsewhere in this repo's hl.* usage) -- this uses the leaf/enabled
-- convention already proven working on "fade"/"windows" above instead
-- of trusting that a second, different property name is right.
hl.animation({ leaf = "layersIn", enabled = false })
hl.animation({ leaf = "layersOut", enabled = false })
