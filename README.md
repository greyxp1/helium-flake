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
{ config, pkgs, helium, ... }:

{
  imports = [helium.nixosModules.helium];
  home-manager.users.${YOUR_USERNAME} = {
    imports = [helium.homeModules.helium];

    programs.helium = {
      enable = true;
      defaultBrowser = true;

      flags = [
        "--ozone-platform-hint=auto"
        "--enable-features=HeliumMiddleClickAutoscroll"
      ];

      extraPolicies = {
        ExtensionInstallForcelist = [
          "ghmbeldphafepmbegfdlkpapadhbakde" # Proton Pass
          "ldgfbffkinooeloadekpmfoklnobpien" # Raindrop.io
          "mnjggcdmjocbbbhaepdhchncahnbgone" # SponsorBlock
        ];

        ExtensionSettings = {
          "ghmbeldphafepmbegfdlkpapadhbakde".toolbar_pin = "force_pinned"; # Proton Pass
          "ldgfbffkinooeloadekpmfoklnobpien".toolbar_pin = "force_pinned"; # Raindrop.io
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
| `extraPolicies`        | attribute set    | `{}`                   | Raw Chromium policies to apply.                     |
| `preferences`          | attribute set    | `{}`                   | Json that will be merged into XDG Config.           |
| `defaultBrowser`       | boolean          | `false`                | Set Helium as the default browser in XDG mimeapps.  |
| `nativeMessagingHosts` | list of packages | `[]`                   | Native messaging host packages to expose to Helium. |

## Policies

Since Helium is based on Chromium, you can use any of the standard Chromium policies in the `extraPolicies` block. You can find a full list of available names and values at the [Chrome Enterprise Policy List](https://chromeenterprise.google/policies/).

Common useful policies:

- `BrowserSignin`: Set to `0` to disable account sign-in.
- `BookmarkBarEnabled`: Set to `true` to force the bookmark bar to show.
- `URLBlocklist`: A list of URL patterns to block.

## Preferences

These are usually what you imperatively choose in the `Settings` menu. You can find all the json keys and values inside the helium browser by typing `helium://prefs-internals/` and searching for the values.

```nix
{
  programs.helium.preferences = {
    browser.show_home_button = false;
    helium.browser.layout = 1;
    bookmark_bar = {
      show_apps_shortcut = false;
      show_managed_bookmarks = false;
      show_on_all_tabs = false;
      show_tab_groups = false;
    };
  };
}
```
