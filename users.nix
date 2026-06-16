let
  owner = {
    name = "Fabian Heinrich";
    email = "fabianheinrich@aol.com";
  };

  mkUser =
    {
      username,
      homeDirectory,
      system,
      name ? owner.name,
      email ? owner.email,
    }:
    {
      inherit
        name
        email
        username
        homeDirectory
        system
        ;
    };
in
{
  inherit owner;

  users = {
    fabian = mkUser {
      username = "fabian";
      homeDirectory = "/Users/fabian";
      system = "aarch64-darwin";
    };
    ubuntu-dev = mkUser {
      username = "ubuntu-dev";
      homeDirectory = "/home/ubuntu-dev";
      system = "x86_64-linux";
    };
    euler = mkUser {
      username = "euler";
      homeDirectory = "/home/euler";
      system = "x86_64-linux";
    };
  };
}
