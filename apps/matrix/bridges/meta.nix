{
  config,
  _utils,
  _domain_base,
  ...
}:
let
  secrets = _utils.setupSecrets config {
    secrets = [
      "matrix/shared_secret"
    ];
  };
in
{
  imports = [
    secrets.generate
  ];

  services.mautrix-meta = {
    instances = {
      instagram = {
        enable = true;

        environmentFile = secrets.get "matrix/shared_secret";
        registerToSynapse = true;

        settings = {
          homeserver = {
            address = "http://localhost:8008";
            domain = _domain_base;
          };

          bridge = {
            permissions = {
              "*" = "relay";
              "${_domain_base}" = "user";
              "@flashonfire:${_domain_base}" = "admin";
            };

            sync_direct_chat_list = true;
          };

          double_puppet = {
            secrets = {
              "${_domain_base}" = "as_token:$SHARED_AS_TOKEN";
            };
          };

          encryption = {
            require = false;
            msc4190 = true;
          };

          database = {
            type = "postgres";
            uri = "postgresql:///mautrix-meta-instagram?host=/run/postgresql";
          };

          network = {
            mode = "instagram";
            displayname_template = "{{ or .DisplayName .Username .ID }} (Instagram)";
          };
        };
      };

      facebook.enable = false;
      messenger.enable = false;
    };
  };

  postgres.initialScripts = [
    ''
      CREATE USER "mautrix-meta-instagram";
      CREATE DATABASE "mautrix-meta-instagram" WITH OWNER "mautrix-meta-instagram"
        TEMPLATE template0
        LC_COLLATE = "C"
        LC_CTYPE = "C";
    ''
  ];
}
