{ pkgs, ... }:

# CAP_PERFMON for intel_gpu_top alone, not a paranoia-level sysctl change
# or running anything as root — home/syland-sysstats.nix (the widget's
# own backend script) shells out to the wrapped binary at
# /run/wrappers/bin/intel_gpu_top specifically for the GPU busy% reading
# windows/StatsModule.qml shows. Plain `intel-gpu-tools` on PATH fails
# with "Permission denied" for a normal user — confirmed live — since
# reading GPU PMU counters needs this capability.
{
  security.wrappers.intel_gpu_top = {
    owner = "root";
    group = "root";
    capabilities = "cap_perfmon+ep";
    source = "${pkgs.intel-gpu-tools}/bin/intel_gpu_top";
  };
}
