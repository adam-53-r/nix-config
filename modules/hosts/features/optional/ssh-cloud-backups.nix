# ssh host entry for the Hetzner storage box that holds offsite backups. The
# account id doubles as the hostname, so the block is rendered from sops to
# keep it out of the public repo.
{
  flake.nixosModules.optionalSshCloudBackups = {config, ...}: let
    user = config.sops.placeholder.cloud-backups-user;
  in {
    key = "mynix#nixosModules.optionalSshCloudBackups";

    sops.secrets.cloud-backups-user = {
      sopsFile = ../../common/users/secrets.json;
    };

    sops.templates."ssh-cloud-backups" = {
      owner = "adamr";
      content = ''
        Host cloud-backups
          HostName ${user}.your-storagebox.de
          Port 23
          User ${user}
      '';
    };

    home-manager.users.adamr.programs.ssh.includes = [
      config.sops.templates."ssh-cloud-backups".path
    ];
  };
}
