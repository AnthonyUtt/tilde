{
  security.rtkit.enable = true;
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    extraConfig = {
      pipewire = {
        "10-clock-rate" = {
          "context.properties" = {
            "default.clock.rate" = 48000;
            "default.clock.allowed-rates" = [ 48000 ];
            "default.clock.quantum" = 2048;
            "default.clock.min-quantum" = 1024;
          };
        };
      };
      pipewire-pulse = {
        "11-latency" = {
          context.modules = [
            {
              name = "libpipewire-module-protocol-pulse";
              args = {
                pulse.min.req = "1024/48000";
                pulse.default.req = "2048/48000";
                pulse.max.req = "2048/48000";
                pulse.min.quantum = "1024/48000";
                pulse.max.quantum = "2048/48000";
              };
            }
          ];
          stream.properties = {
            node.latency = "2048/48000";
          };
        };
      };
    };
  };
}
