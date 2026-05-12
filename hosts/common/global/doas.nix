{
  security = {
    sudo.enable = false;
    doas = {
      enable = true;
      extraRules = [{
        users = [ "anthony" ];
        keepEnv = true;
        noPass = true;
      }];
    };
  };
}
