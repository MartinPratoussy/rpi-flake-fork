{
  config,
  _utils,
  _domain_base,
  ...
}:

let
  secrets = _utils.setupSecrets config {
    secrets = [
      "wealthfolio/secret-key"
    ];
  };
in
{

  imports = [
    secrets.generate
  ];

  services.wealthfolio = {
    enable = true;
    secretKeyFile = secrets.get "wealthfolio/secret-key";
    authRequired = false;
    corsAllowOrigins = "https://wealthfolio.${_domain_base}";
  };

}
