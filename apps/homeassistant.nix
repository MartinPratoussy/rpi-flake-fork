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

      automation = [
        {
          id = "dimmer_chambre_ampoule_aqara";
          alias = "Dimmer chambre -> Ampoule Aqara";
          triggers = [
            {
              trigger = "state";
              entity_id = "event.dimmer_chambre_action";
              attribute = "event_type";
              to = "single";
              id = "toggle";
            }
            {
              trigger = "state";
              entity_id = "event.dimmer_chambre_action";
              attribute = "event_type";
              to = "double";
              id = "full_bright";
            }
            {
              trigger = "state";
              entity_id = "event.dimmer_chambre_action";
              attribute = "event_type";
              to = "hold";
              id = "turn_off";
            }
            {
              trigger = "state";
              entity_id = "event.dimmer_chambre_action";
              attribute = "event_type";
              to = "rotation";
              id = "dim";
            }
          ];
          conditions = [ ];
          actions = [
            {
              choose = [
                {
                  conditions = [
                    {
                      condition = "trigger";
                      id = "toggle";
                    }
                  ];
                  sequence = [
                    {
                      action = "light.toggle";
                      target.entity_id = "light.led_bulb_t2_e27_rgb_cct";
                    }
                  ];
                }
                {
                  conditions = [
                    {
                      condition = "trigger";
                      id = "full_bright";
                    }
                  ];
                  sequence = [
                    {
                      action = "light.turn_on";
                      target.entity_id = "light.led_bulb_t2_e27_rgb_cct";
                      data.brightness_pct = 100;
                    }
                  ];
                }
                {
                  conditions = [
                    {
                      condition = "trigger";
                      id = "turn_off";
                    }
                  ];
                  sequence = [
                    {
                      action = "light.turn_off";
                      target.entity_id = "light.led_bulb_t2_e27_rgb_cct";
                    }
                  ];
                }
                {
                  conditions = [
                    {
                      condition = "trigger";
                      id = "dim";
                    }
                  ];
                  sequence = [
                    {
                      action = "light.turn_on";
                      target.entity_id = "light.led_bulb_t2_e27_rgb_cct";
                      data.brightness_step_pct = "{{ states('sensor.0x54ef44100123fe40_action_rotation_percent_speed') | float(0) | round(0) }}";
                    }
                  ];
                }
              ];
            }
          ];
          mode = "restart";
        }
      ];
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
