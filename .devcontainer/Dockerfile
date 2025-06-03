FROM mcr.microsoft.com/devcontainers/base:alpine
# FROM mcr.microsoft.com/devcontainers/base:bookworm


USER vscode
RUN curl -L https://nixos.org/nix/install | sh -s -- --no-daemon --yes

# WORKDIR /home/vscode/nix
# RUN git clone https://github.com/fabian1heinrich/nix.git .
# RUN USER=$(id -un) PATH=/home/vscode/.nix-profile/bin:$PATH NIX_USER_CONF_FILES=configuration.nix nix run nixpkgs#home-manager -- switch --flake .#devcontainer-x86_64-linux


# ENV \
# PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/home/vscode/.local/bin:/home/vscode/.nix-profile/bin