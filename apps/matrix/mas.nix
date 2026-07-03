{
  config,
  _utils,
  _domain_base,
  ...
}:
let
  secrets = _utils.setupSecrets config {
    secrets = [
      "mas/encryption"
      "mas/key_rsa_4096"
      "mas/key_ec_p384"
      "mas/client_secret"
      "mas/matrix_secret"
      "mas/provider_client_secret"
    ];
  };

  port = 8089;
  port2 = 8083;

  credentialPath = name: "/run/credentials/matrix-authentication-service.service/${name}";
in
{
  imports = [
    secrets.generate
  ];

  services.matrix-authentication-service = {
    enable = true;
    serviceDependencies = [
      config.services.matrix-synapse.serviceUnit
      "postgresql.service"
    ];

    createDatabase = true;

    credentials = {
      "encryption" = secrets.get "mas/encryption";
      "key_rsa_4096" = secrets.get "mas/key_rsa_4096";
      "key_ec_p384" = secrets.get "mas/key_ec_p384";
      "client_secret" = secrets.get "mas/client_secret";
      "matrix_secret" = secrets.get "mas/matrix_secret";
      "provider_client_secret" = secrets.get "mas/provider_client_secret";
    };

    settings = {

      http = {
        listeners = [
          {
            name = "web";
            resources = [
              { name = "discovery"; }
              { name = "human"; }
              { name = "oauth"; }
              { name = "compat"; }
              { name = "graphql"; }
              { name = "assets"; }
            ];
            binds = [
              { address = "[::1]:${toString port}"; }
            ];
            proxy_protocol = false;
          }
          {
            name = "internal";
            resources = [
              { name = "health"; }
            ];
            binds = [
              {
                host = "localhost";
                port = port2;
              }
            ];
            proxy_protocol = false;
          }
        ];

        trusted_proxies = [
          "127.0.0.1/8"
          "::1/128"
        ];

        public_base = "https://mas.${_domain_base}/";
        issuer = "https://mas.${_domain_base}/";
      };

      email = {
        from = "\"Authentication Service\" <root@localhost>";
        reply_to = "\"Authentication Service\" <root@localhost>";
        transport = "blackhole";
      };

      secrets = {
        encryption_file = credentialPath "encryption";
        keys = [
          {
            kid = "rsa-4096";
            key_file = credentialPath "key_rsa_4096";
          }
          {
            kid = "ec-p384";
            key_file = credentialPath "key_ec_p384";
          }
        ];
      };

      passwords = {
        enabled = false;
      };

      matrix = {
        homeserver = _domain_base;
        endpoint = "http://[::1]:8008/";
        secret_file = credentialPath "matrix_secret";
      };

      clients = [
        {
          client_id = "0000000000000000000SYNAPSE";
          client_auth_method = "client_secret_basic";
          client_secret_file = credentialPath "client_secret";
        }
      ];

      upstream_oauth2.providers = [
        {
          id = "01KJKAM7BDPSYJDN4YXSZQYX1H";
          human_name = "Authelia";
          issuer = "https://auth.${_domain_base}";
          client_id = "IkhbiLxn.MQVKQeBFAlvMfu3-RdUMScM0PcnpDSyjSTGwjs0VGveq_yii.GOavtNyoZYC9U6";
          client_secret_file = credentialPath "provider_client_secret";
          token_endpoint_auth_method = "client_secret_basic";
          scope = "openid profile email";
          fetch_userinfo = true;
          claims_imports = {
            localpart = {
              action = "require";
              on_conflict = "fail";
              on_backchannel_logout = "logout_all";
              template = "{{ user.preferred_username }}";
            };
            displayname = {
              action = "suggest";
              template = "{{ user.name }}";
            };
            email = {
              action = "suggest";
              template = "{{ user.email }}";
              set_email_verification = "always";
            };
          };
        }
      ];

    };

  };

}
