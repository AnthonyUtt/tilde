let
  mkLockedAttrs = builtins.mapAttrs (_: value: {
    Value = value;
    Status = "locked";
  });

  mkPluginUrl = id: "https://addons.mozilla.org/firefox/downloads/latest/${id}/latest.xpi";

  mkExtensionEntry = {
    id,
    pinned ? false,
  }: let
    base = {
      install_url = mkPluginUrl id;
      installation_mode = "force_installed";
    };
  in
    if pinned
    then base // {default_area = "navbar";}
    else base;

  mkExtensionSettings = builtins.mapAttrs (_: entry:
    if builtins.isAttrs entry
    then entry
    else mkExtensionEntry {id = entry;});
in
{
  AutofillAddressEnabled = false;
  AutofillCreditCardEnabled = false;
  DisableAppUpdate = true;
  DisableFeedbackCommands = true;
  DisableFirefoxStudies = true;
  DisablePocket = true;
  DisableTelemetry = true;
  DontCheckDefaultBrowser = true;
  OfferToSaveLogins = false;
  EnableTrackingProtection = {
    Value = true;
    Locked = true;
    Cryptomining = true;
    Fingerprinting = true;
  };

  ExtensionSettings = mkExtensionSettings {
    "uBlock0@raymondhill.net" = mkExtensionEntry {
      id = "ublock-origin";
      pinned = true;
    };
    "{446900e4-71c2-419f-a6a7-df9c091e268b}" = mkExtensionEntry {
      id = "bitwarden-password-manager";
      pinned = true;
    };
    "jordanlinkwarden@gmail.com" = mkExtensionEntry {
      id = "linkwarden";
      pinned = true;
    };
  };
  Preferences = mkLockedAttrs {
    "browser.aboutConfig.showWarning" = false;
    "browser.tabs.warnOnClose" = false;
    "media.videocontrols.picture-in-picture.video-toggle.enabled" = false;
    "browser.gesture.swipe.left" = "";
    "browser.gesture.swipe.right" = "";
    "browser.tabs.hoverPreview.enabled" = true;
  };
}
