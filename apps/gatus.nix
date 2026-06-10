{
  _domain_base,
  ...
}:
let
  port = 3001;
  httpOk = [
    "[STATUS] == 200"
    "[RESPONSE_TIME] < 1000"
  ];
  httpUp = [
    "[STATUS] < 400"
    "[RESPONSE_TIME] < 1000"
  ];
  tcpOk = [
    "[CONNECTED] == true"
    "[RESPONSE_TIME] < 1000"
  ];
in
{
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
          name = "Gatus";
          group = "core";
          url = "http://127.0.0.1:${toString port}/";
          conditions = httpOk;
        }
        {
          name = "Authelia";
          group = "core";
          url = "https://auth.${_domain_base}";
          conditions = httpUp;
        }
        {
          name = "Ntfy";
          group = "core";
          url = "https://ntfy.${_domain_base}/v1/health";
          conditions = httpOk;
        }
        {
          name = "Forgejo";
          group = "apps";
          url = "http://127.0.0.1:3004/api/healthz";
          conditions = httpOk ++ [ "[BODY].status == pass" ];
        }
        {
          name = "Grafana";
          group = "apps";
          url = "http://127.0.0.1:3000/api/health";
          conditions = httpOk ++ [ "[BODY].database == ok" ];
        }
        {
          name = "VaultWarden";
          group = "apps";
          url = "http://[::1]:8222/alive";
          conditions = httpOk;
        }
        {
          name = "Immich";
          group = "apps";
          url = "tcp://127.0.0.1:2283";
          conditions = tcpOk;
        }
        {
          name = "Home Assistant";
          group = "apps";
          url = "http://[::1]:8123/";
          conditions = httpOk;
        }
        {
          name = "OxiCloud";
          group = "apps";
          url = "tcp://127.0.0.1:8086";
          conditions = tcpOk;
        }
        {
          name = "AdGuard";
          group = "infra";
          url = "http://127.0.0.1:3005/";
          conditions = httpUp;
        }
        {
          name = "OpenThread Border Router";
          group = "infra";
          url = "http://127.0.0.1:8082/";
          conditions = httpOk;
        }
        {
          name = "ssh";
          group = "infra";
          url = "tcp://127.0.0.1:22";
          conditions = tcpOk;
        }
        {
          name = "Matrix Synapse";
          group = "matrix";
          url = "http://[::1]:8008/_matrix/client/versions";
          conditions = httpOk;
        }
        {
          name = "Matrix Authentication Service";
          group = "matrix";
          url = "tcp://[::1]:8083";
          conditions = tcpOk;
        }
        {
          name = "Livekit JWT";
          group = "matrix";
          url = "http://[::1]:8080/healthz";
          conditions = httpOk;
        }
        {
          name = "Livekit";
          group = "matrix";
          url = "tcp://127.0.0.1:7880";
          conditions = tcpOk;
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
}
