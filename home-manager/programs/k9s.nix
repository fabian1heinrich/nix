{ pkgs, catppuccin-k9s, ... }:
let
  skinsPath =
    if pkgs.stdenv.isDarwin then "Library/Application Support/k9s/skins" else ".config/k9s/skins";
in
{
  programs.k9s = {
    enable = true;
    settings = {
      k9s = {
        liveViewAutoRefresh = true;
        refreshRate = 2;
        apiServerTimeout = "30s";
        maxConnRetry = 5;
        readOnly = false;
        noExitOnCtrlC = false;
        portForwardAddress = "localhost";
        ui = {
          # Avoid accidental context actions from mouse clicks.
          enableMouse = false;
          headless = false;
          logoless = true;
          crumbsless = false;
          reactive = false;
          noIcons = false;
          skin = "catppuccin-mocha";
        };
        # Reduce periodic update checks/noise.
        skipLatestRevCheck = true;
        disablePodCounting = false;
        shellPod = {
          image = "busybox:1.36";
          namespace = "default";
          limits = {
            cpu = "100m";
            memory = "100Mi";
          };
          tty = true;
        };
        imageScans = {
          enable = false;
          exclusions = {
            namespaces = [ "kube-system" ];
          };
        };
        logger = {
          tail = 200;
          buffer = 5000;
          # Live tail by default when opening logs.
          sinceSeconds = -1;
          fullScreen = false;
          textWrap = false;
          showTime = true;
        };
        thresholds = {
          cpu = {
            critical = 90;
            warn = 70;
          };
          memory = {
            critical = 90;
            warn = 70;
          };
        };
      };
    };
  };

  home.file.${skinsPath}.source = "${catppuccin-k9s}/dist";
}
