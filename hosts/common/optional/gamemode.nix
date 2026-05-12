{ pkgs, ... }: {
  programs.gamemode = {
    enable = true;
    settings = {
      general = {
        softrealtime = "on";
        inhibit_screensaver = 1;
      };
      gpu = {
        apply_gpu_optimisations = "accept-responsibility";
        gpu_device = 0;
        amd_performance_level = "high";
      };
    };
  };

  environment.systemPackages = [
    pkgs.vulkan-tools
    pkgs.nvtopPackages.nvidia
    pkgs.gamescope
    pkgs.mangohud
  ];

  security.pam.loginLimits = [
    {
      domain = "*";
      item = "nofile";
      type = "-";
      value = "1048576";
    }
  ];

  systemd = {
    extraConfig = ''
      DefaultLimitNOFILE=1048576
    '';
    user.extraConfig = ''
      DefaultLimitNOFILE=1048576
    '';
  };
}
