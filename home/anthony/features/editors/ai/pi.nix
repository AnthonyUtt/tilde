{ pkgs, inputs, ... }: {
  programs.pi-coding-agent = {
    enable = true;
    extraPackages = with pkgs; [
      nodejs
      bun
      inputs.qmd.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
    models = {
      providers = {
        omlx = {
          baseUrl = "https://omlx.uttho.me/v1";
          api = "openai-completions";
          apiKey = "$OMLX_API_KEY";
          compat = {
            supportsDeveloperRole = false;
            supportsReasoningEffort = false;
          };
          models = [
            {
              id = "Ornith-1.5-35B-A3B-MLX-4bit";
              reasoning = true;
            }
          ];
        };
      };
    };
  };
}
