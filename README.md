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
      flags = [
        "--enable-features=HeliumMiddleClickAutoscroll"
        "--enable-parallel-downloading"
      ];

      extensions = {
        sponsorBlock.id = "mnjggcdmjocbbbhaepdhchncahnbgone";
        darkReader = {
          id = "eimadpbcbfnmbkopoojfekhnkhdbieeh";
          pin = true;
        };
      };

      preferences = {
        browser.show_forward_button = false;
        session.restore_on_startup = 2;
        helium.browser = {
          layout = 2;
          show_avatar_button = false;
          show_back_button = false;
          show_reload_button = false;
          show_vertical_tabs_collapse_button = false;
          zen_mode = true;
          zen_mode_sidebar_pinned = true;
          zen_mode_top_chrome_pinned = true;
        };
      };
    };
  };
}
```

## Credits

- Most of the original flake, package, NixOS module, and Home Manager module code is from [ntgn's helium-flake](https://gitlab.com/ntgn/helium-flake).
- This fork contains my changes on top of their work.
