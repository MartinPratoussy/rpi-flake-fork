{
  config,
  lib,
  my-cinematek,
  pkgs,
  _utils,
  ...
}:
let
  cfg = config.services.my-cinematek;
  python = pkgs.python3.withPackages (packages: [ packages.psycopg ]);

  # Only the app files: the server statically serves its working directory,
  # so the repo's committed database and docs must stay out of it.
  appFiles = pkgs.runCommandLocal "my-cinematek-files" { } ''
    mkdir -p "$out"
    cp ${my-cinematek}/{server.py,index.html,admin.html,app.js,admin.js,public.js,styles.css} "$out/"
  '';

  secrets = _utils.setupSecrets config {
    secrets = [ "my-cinematek/env" ];
  };
in
{
  imports = [ secrets.generate ];

  options.services.my-cinematek = {
    enable = lib.mkEnableOption "my-cinematek";
    port = lib.mkOption {
      type = lib.types.port;
      default = 8000;
      description = "TCP port listened to by my-cinematek.";
    };
    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Root-managed environment file containing AUTHOR_PASSWORD and optional TMDB_API_KEY or DATABASE_URL.";
    };
  };

  config = lib.mkMerge [
    {
      services.my-cinematek.enable = lib.mkDefault true;
      services.my-cinematek.environmentFile = lib.mkDefault (toString (secrets.get "my-cinematek/env"));
    }
    (lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = cfg.environmentFile != null;
          message = "services.my-cinematek.environmentFile must provide AUTHOR_PASSWORD.";
        }
      ];

      systemd.services.my-cinematek = {
        description = "my-cinematek film journal";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];
        serviceConfig = {
          ExecStart = "${python}/bin/python ${appFiles}/server.py";
          WorkingDirectory = "${appFiles}";
          Environment = [
            "PORT=${toString cfg.port}"
            "SQLITE_PATH=/var/lib/my-cinematek/my-cinematek.db"
          ];
          EnvironmentFile = cfg.environmentFile;
          Restart = "on-failure";
          DynamicUser = true;
          StateDirectory = "my-cinematek";
          StateDirectoryMode = "0700";
          ProtectHome = true;
          ProtectSystem = "strict";
          PrivateTmp = true;
          NoNewPrivileges = true;
        };
      };
    })
  ];
}