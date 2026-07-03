{ lib, pkgs, ... }:
{
  programs.helix = {
    enable = true;
    defaultEditor = true;

    extraPackages = with pkgs; [
      nixd
      nixfmt
    ];

    settings = {
      theme = "github_dark_dimmed";
      editor = {
        bufferline = "multiple";
        color-modes = true;
        cursorline = true;
        line-number = "relative";
        mouse = true;
        true-color = true;

        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };

        file-picker = {
          hidden = false;
        };

        indent-guides = {
          render = true;
        };

        lsp = {
          display-messages = true;
        };

        statusline = {
          left = [
            "mode"
            "spinner"
            "file-name"
            "read-only-indicator"
            "file-modification-indicator"
          ];
          center = [ "version-control" ];
          right = [
            "diagnostics"
            "selections"
            "register"
            "position"
            "file-encoding"
          ];
        };
      };
    };

    languages = {
      language-server.nixd = {
        command = lib.getExe pkgs.nixd;
      };

      language = [
        {
          name = "nix";
          auto-format = true;
          formatter = {
            command = lib.getExe pkgs.nixfmt;
          };
          language-servers = [ "nixd" ];
        }
      ];
    };
  };
}
