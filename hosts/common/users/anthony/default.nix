{ pkgs, config, ... }:
let
  ifTheyExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
in
{
  users.mutableUsers = false;
  users.users.anthony = {
    hashedPassword = "$y$j9T$E7ZcyDG8mE.ozvXGK3ZR.0$mojgJ8zWLH1PIJ8gSGKmltZoCBn8ows7LrgfowSQk.D";
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [
      "wheel"
      "audio"
      "video"
      "dialout"
      "keys"
    ] ++ ifTheyExist [
      "network"
      "docker"
      "git"
      "input"
      "uinput"
      "libvirtd"
      "kvm"
    ];
    packages = [ pkgs.home-manager ];
  };
}
