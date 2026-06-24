{ self, ... }:
{
  flake = {
    homeModules.helium = import ./home-manager.nix { inherit self; };
    nixosModules.helium = import ./nixos.nix;
  };
}
