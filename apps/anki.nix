{
  config,
  _utils,
  ...
}:
let
  secrets = _utils.setupSecrets config {
    secrets = [
      "anki/flashonfire"
    ];
  };

  storageDir = "/storage/anki";
in
{
  imports = [
    secrets.generate
  ];

  users.groups.anki-sync = { };

  systemd.tmpfiles.rules = [
    "d ${storageDir} 0770 root anki-sync -"
  ];

  systemd.services.anki-sync-server.serviceConfig = {
    SupplementaryGroups = [ "anki-sync" ];
    ReadWritePaths = [ storageDir ];
  };

  services.anki-sync-server = {
    enable = true;
    baseDirectory = storageDir;
    users = [
      {
        username = "flashonfire";
        passwordFile = secrets.get "anki/flashonfire";
      }
    ];
  };
}
