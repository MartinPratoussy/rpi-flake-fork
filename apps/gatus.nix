{
  lib,
  _domain_base,
  ...
}:
let
  port = 3001;
in
{
  users.users.gatus = {
    isSystemUser = true;
    group = "gatus";
    description = "Gatus service user";
  };
  users.groups.gatus = { };

  services.gatus = {
    enable = true;
    settings = {
      web = {
        address = "127.0.0.1";
        port = port;
      };
      storage = {
        type = "postgres";
        path = "postgres://gatus@/gatus?host=/run/postgresql";
      };
      endpoints = [
        {
          name = "status";
          url = "http://127.0.0.1:${toString port}/";
          conditions = [ "[STATUS] == 200" ];
        }
        {
          name = "forgejo";
          url = "http://127.0.0.1:3004/api/healthz";
          conditions = [ "[STATUS] == 200" ];
        }
      ];
    };
  };

  services.postgresql.ensureUsers = [
    {
      name = "gatus";
      ensureDBOwnership = true;
    }
  ];
  services.postgresql.ensureDatabases = [ "gatus" ];

  # systemd.services.gatus.serviceConfig.DynamicUser = lib.mkForce false;
}
