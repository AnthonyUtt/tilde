{ pkgs, ... }: {
  programs.ssh = {
    enable = true;
    extraConfig = ''
Host gh
    HostName github.com
    PreferredAuthentications publickey
    IdentityFile /home/anthony/.ssh/id_rsa
    User git

Host opnsense
    Hostname opnsense.utthome.local
    PreferredAuthentications publickey
    IdentityFile /home/anthony/.ssh/id_rsa
    User admin

Host hashbrown
    Hostname hashbrown.utthome.local
    PreferredAuthentications publickey
    IdentityFile /home/anthony/.ssh/id_rsa
    User anthony

Host homefry
    Hostname homefry.utthome.local
    PreferredAuthentications publickey
    IdentityFile /home/anthony/.ssh/id_rsa
    User anthony

Host spud
    Hostname spud.utthome.local
    PreferredAuthentications publickey
    IdentityFile /home/anthony/.ssh/id_rsa
    User anthony

Host gaia
    Hostname gaia.utthome.local
    PreferredAuthentications publickey
    IdentityFile /home/anthony/.ssh/id_rsa
    User anthony
    '';
  };
}
