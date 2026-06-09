{
  config,
  _domain_base,
  _utils,
  ...
}:

let
  secrets = _utils.setupSecrets config {
    secrets = [
      "ntfy/users"
    ];
    extra = {
      owner = "ntfy-sh";
      group = "ntfy-sh";
    };
  };
in
{
  imports = [
    secrets.generate
  ];

  services.ntfy-sh = {
    enable = true;
    settings = {
      base-url = "https://ntfy.${_domain_base}";

      listen-http = "[::1]:8084";

      auth-default-access = "deny-all";

      enable-login = true;
      require-login = true;
      behind-proxy = true;

      database-url = "postgres://ntfy-sh?host=/run/postgresql";
      auth-file = "";
      cache-file = "";

      auth-access = [
        "*:up*:write-only"
        # "flashonfire:*:rw"
      ];
    };
    environmentFile = secrets.get "ntfy/users";
  };

  services.postgresql.ensureUsers = [
    {
      name = "ntfy-sh";
      ensureDBOwnership = true;
    }
  ];
  services.postgresql.ensureDatabases = [ "ntfy-sh" ];
}
