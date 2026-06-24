# helium-flake

Forked from [helium-flake](https://gitlab.com/AlexLov/helium-flake). Credit goes to them.

## Quick start

```sh
nix run github:greyxp1/helium-flake
```

## Usage

Add the flake to your inputs:

```nix
helium.url = "github:greyxp1/helium-flake";
```

## Configuration

```nix
{ helium, ... }:

{
  imports = [helium.nixosModules.helium];
  home-manager.users.${YOUR_USERNAME} = {
    programs.helium = {
      enable = true;
      defaultBrowser = true;

      flags = [
        "--ozone-platform-hint=auto"
        "--enable-features=HeliumMiddleClickAutoscroll"
      ];

      extensions = {
        darkReader.id = "eimadpbcbfnmbkopoojfekhnkhdbieeh";
        sponsorBlock.id = "mnjggcdmjocbbbhaepdhchncahnbgone";

        protonPass = {
          id = "ghmbeldphafepmbegfdlkpapadhbakde";
          pin = true;
        };

        raindrop = {
          id = "ldgfbffkinooeloadekpmfoklnobpien";
          pin = true;
        };
      };

      preferences = {
        browser.show_forward_button = false;
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

## Options Reference

The following options are available under `programs.helium`:

| Option                 | Type             | Default                | Description                                         |
| :--------------------- | :--------------- | :--------------------- | :-------------------------------------------------- |
| `enable`               | boolean          | `false`                | Whether to enable the Helium browser module.        |
| `package`              | package          | `self.packages.helium` | The helium package to use.                          |
| `flags`                | list of strings  | `[]`                   | Command line arguments passed to the wrapper.       |
| `extensions`           | attribute set    | `{}`                   | Chrome Web Store extension IDs, with optional pins. |
| `extraPolicies`        | attribute set    | `{}`                   | Chromium policies written to managed policy files.  |
| `preferences`          | attribute set    | `{}`                   | Browser settings merged into the default profile.   |
| `defaultBrowser`       | boolean          | `false`                | Set Helium as the default browser in XDG mimeapps.  |
| `nativeMessagingHosts` | list of packages | `[]`                   | Native messaging host packages to expose to Helium. |

`extraPolicies` accepts standard Chromium policy names. See the [Chrome Enterprise Policy List](https://chromeenterprise.google/policies/) for available keys.

`preferences` uses the same keys Helium stores in the profile `Preferences` file. You can inspect them at `helium://prefs-internals/`.
