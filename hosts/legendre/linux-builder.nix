{ pkgs, ... }:
{
  # Native ARM Linux guest; Rosetta executes x86_64 Linux build processes.
  # This builds amd64 installation media but cannot boot its x86_64 kernel.
  nix.linux-builder = {
    enable = true;
    package = pkgs.darwin.linux-builder-vz;
    systems = [
      "aarch64-linux"
      "x86_64-linux"
    ];
    # Preserve downloaded and built store paths across builder restarts.
    ephemeral = false;
    maxJobs = 1;
    # Do not advertise KVM: nested ARM virtualisation cannot accelerate x86 VMs.
    supportedFeatures = [
      "benchmark"
      "big-parallel"
    ];
    config.nix.settings = {
      # Concurrent downloads can exhaust this small guest's memory.
      max-substitution-jobs = 1;
      # The guest root is tmpfs; unpack large builds on the writable disk.
      build-dir = "/nix/.rw-store/builds";
    };
    config.virtualisation = {
      cores = 2;
      darwin-builder = {
        memorySize = 4 * 1024;
        diskSize = 40 * 1024;
      };
    };
  };
}
