{
  config,
  _utils,
  _domain_base,
  ...
}:
let

  secrets = _utils.setupSecrets config {
    secrets = [
      "ddclient/dynhost-password"
    ];
  };
in
{
  imports = [
    secrets.generate
  ];

  services.ddclient = {
    enable = true;

    domains = [ "${_domain_base}" ];
    username = "${_domain_base}-lithium";
    passwordFile = secrets.get "ddclient/dynhost-password";
    protocol = "ovh";
    server = "www.ovh.com";
  };
}
