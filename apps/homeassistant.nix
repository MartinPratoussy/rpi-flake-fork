{
  config,
  pkgs,
  _domain_base,
  _utils,
  ...
}:
let
  secrets = _utils.setupSecrets config {
    secrets = [
      "hass/secrets"
    ];
    extra = {
      owner = "hass";
      group = "hass";
      path = "/var/lib/hass/secrets.yaml";
    };
  };
in
{
  imports = [
    secrets.generate
  ];

  services.home-assistant = {
    enable = true;
    extraComponents = [
      # Components required to complete the onboarding
      "analytics"
      "google_translate"
      "met"
      "radio_browser"
      "shopping_list"
      # Recommended for fast zlib compression
      # https://www.home-assistant.io/integrations/isal
      "isal"

      "matter"
      "otbr"
      "thread"
      "mqtt"
    ];

    customComponents = with pkgs.home-assistant-custom-components; [
      auth_oidc
    ];

    extraPackages = ps: with ps; [ psycopg2 ];

    config = {
      # Includes dependencies for a basic setup
      # https://www.home-assistant.io/integrations/default_config/
      default_config = { };

      homeassistant = {
        auth_providers = [ ];
      };

      http = {
        server_host = "::1";
        trusted_proxies = [ "::1" ];
        use_x_forwarded_for = true;
      };

      recorder.db_url = "postgresql://@/hass";

      auth_oidc = {
        client_id = "EvMODCopeyM1DRs1QEPItPv4YHCkYE--pFefjtm.c5YCf1.3YpCJyYL0QVwizhaM2lOXXLYm";
        client_secret = "!secret oidc_client_secret";
        discovery_url = "https://auth.${_domain_base}/.well-known/openid-configuration";
        display_name = "Authelia";

        roles = {
          user = "non_existent";
          admin = "owner";
        };
      };
    };
  };

  services.postgresql = {
    enable = true;
    ensureDatabases = [ "hass" ];
    ensureUsers = [
      {
        name = "hass";
        ensureDBOwnership = true;
      }
    ];
  };
}
