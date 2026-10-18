{ _domain_base, ... }:
{
  services.paperless = {
    enable = false;
    dataDir = "/storage/paperless";

    domain = "paperless.${_domain_base}";
    port = 28981;
    settings = {
      PAPERLESS_OCR_LANGUAGE = "fra+eng";
      PAPERLESS_CONSUMER_IGNORE_PATTERN = [
        ".DS_STORE/*"
        "desktop.ini"
      ];
      PAPERLESS_OCR_USER_ARGS = {
        optimize = 1;
        pdfa_image_compression = "lossless";
      };
    };

    database.createLocally = true;
  };
}
