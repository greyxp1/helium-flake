# helium-flake

A rewrite of [ntgn's helium-flake](https://gitlab.com/ntgn/helium-flake). Suports `x86_64-linux` only.

## Quick start

```sh
nix run github:greyxp1/helium-flake
```

## Installation

Add the flake to your inputs:

```nix
helium.url = "github:greyxp1/helium-flake";
```

## Options

- `enable`: install Helium.
- `defaultBrowser`: register Helium as the default browser.
- `flags`: extra command-line flags from `helium://flags/` passed to Helium.
- `preferences`: options you'd configure in the `Settings` menu. A list of all preferences can be found in `helium://prefs-internals/`.
- `extensions`: Chrome Web Store extensions to force-install.
- `extraPolicies`: Chromium policy values from `helium://policy/` written to managed policy files.

### Extensions

Each extension needs an `id`. Set `pin = true` to force-pin it to the toolbar.

```nix
programs.helium.extensions.darkReader = {
  id = "eimadpbcbfnmbkopoojfekhnkhdbieeh";
  pin = true;
};
```

## Example configuration

```nix
{ helium, ... }:

{
  imports = [helium.nixosModules.helium];
  home-manager.users.grey = {
    programs.helium = {
      enable = true;
      defaultBrowser = true;
      flags = ["--enable-features=HeliumMiddleClickAutoscroll"];

      extraPolicies = {
        RestoreOnStartup = 1;
        HighEfficiencyModeEnabled = true;
        MemorySaverModeSavings = 2;
        DefaultSearchProviderEnabled = true;
        DefaultSearchProviderName = "Google";
        DefaultSearchProviderSearchURL = "https://www.google.com/search?q={searchTerms}";
        DefaultSearchProviderSuggestURL = "https://www.google.com/complete/search?output=chrome&q={searchTerms}";
      };

      extensions = {
        sponsorBlock.id = "mnjggcdmjocbbbhaepdhchncahnbgone";
        deArrow.id = "enamippconapkdmgfgjchkhakpfinmaj";
        controlPanel.id = "lodcanccmfbpjjpnngindkkmiehimile";
        re-start.id = "fdodcmjeojbmcgmhcgcelffcekhicnop";

        ublock = {
          id = "blockjmkbacgjkknlgpkjjiijinjdanf";
          pin = true;
        };

        protonPass = {
          id = "ghmbeldphafepmbegfdlkpapadhbakde";
          pin = true;
        };

        raindrop = {
          id = "ldgfbffkinooeloadekpmfoklnobpien";
          pin = true;
        };

        pipView = {
          id = "eaeedemddlledlghhjebjgdmhjekgegd";
          pin = true;
        };
      };

      preferences = {
        ntp.shortcust_visible = false;
        auto_pin_new_tab_groups = false;
        bookmark_bar.show_tab_groups = false;

        helium = {
          services.user_consented = true;
          browser = {
            layout = 2;
            mru_tab_cycling = true;
            show_avatar_button = false;
            show_back_button = false;
            show_reload_button = false;
            rounded_frame = false;
            show_vertical_tabs_collapse_button = false;
            vertical_right_aligned = true;
          };
        };

        browser = {
          show_forward_button = false;
          custom_chrome_frame = false;
        };
      };
    };
  };
}
```
