{ ... }:
{
  services.mosquitto = {
    enable = true;
  };

  services.zigbee2mqtt = {
    enable = true;
    dataDir = "/storage/zigbee2mqtt";

    settings = {
      permit_join = false;

      homeassistant.experimental_event_entities = true;

      serial = {
        port = "tcp://192.168.1.198:7638";
        adapter = "zstack";
      };

      frontend = {
        enabled = true;
        port = 8099;
        package = "zigbee2mqtt-windfront";
      };

      availability.enabled = true;

      devices = {
        "0x54ef44100123fe40" = {
          friendly_name = "Dimmer Chambre";
          operation_mode = "decoupled";
          power_on_behavior = "on";
          min_brightness = 0;
          max_brightness = 100;
          sensitivity = "medium";
          multi_click = false;
        };
        "0xf044d3fffe5cb303" = {
          friendly_name = "Température/Humidité Chambre";
        };
      };
    };
  };
}
