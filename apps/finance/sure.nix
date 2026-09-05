{
  config,
  pkgs,
  sure-nix,
  _utils,
  _domain_base,
  ...
}:
let
  secrets = _utils.setupSecrets config {
    secrets = [
      "sure/env"
    ];
    extra = {
      owner = "sure";
      group = "sure";
    };
  };
in
{
  imports = [
    secrets.generate
    sure-nix.nixosModules.sure
  ];

  services.redis.servers.sure = {
    enable = true;
    user = "sure";
    unixSocket = "/run/redis-sure/redis.sock";
    unixSocketPerm = 600;
  };
  services.sure = {
    enable = true;
    dataDir = "/storage/sure";
    package = pkgs.sure;

    port = 3002;

    databaseUrl = "postgresql:///sure?host=/run/postgresql";
    environmentFile = secrets.get "sure/env";

    settings = {
      APP_DOMAIN = "https://sure.${_domain_base}";
      REDIS_URL = "unix:///run/redis-sure/redis.sock";
    };
  };

  services.postgresql = {
    ensureDatabases = [ "sure" ];
    ensureUsers = [
      {
        name = "sure";
        ensureDBOwnership = true;
      }
    ];
  };

}
