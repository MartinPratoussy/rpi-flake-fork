{
  config,
  lib,
  _utils,
  ...
}:
let
  secrets = _utils.setupSecrets config {
    secrets = [ "my-cinematek/env" ];
  };
in
{
  imports = [ secrets.generate ];

  config = {
    services.my-cinematek.enable = lib.mkDefault true;
    services.my-cinematek.environmentFile = lib.mkDefault (toString (secrets.get "my-cinematek/env"));
  };
}
