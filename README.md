# helium-flake

> [!IMPORTANT]
> This flake only supports `x86_64-linux`.
>
> This was forked from [helium-flake](https://gitlab.com/AlexLov/helium-flake).
> Without it I'd have had to write the packaging myself, so all credit to them.

## About

Nix flake for the [Helium browser](https://helium.computer/) with a home-manager module for declarative extension and settings management.

## Quick start

### `nix run`

```sh
nix run github:greyxp1/helium-flake
```

### NixOS + home-manager

Add the flake to your inputs:

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url      = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    helium.url       = "github:greyxp1/helium-flake";
  };

  outputs = { nixpkgs, home-manager, helium, ... }: {
    nixosConfigurations.mymachine = nixpkgs.lib.nixosSystem {
      modules = [
        home-manager.nixosModules.home-manager
        helium.nixosModules.helium
        {
          home-manager.users.youruser = {
            imports = [ helium.homeModules.helium ];
            # see configuration below
          };
        }
      ];
    };
  };
}
```

## Configuration

> [!IMPORTANT]
> You need both the NixOS module and the Home Manager module for full configuration support.
> Home Manager installs and wraps Helium, while the NixOS module writes managed policies to `/etc/chromium/policies/managed/`.

```nix
{ config, pkgs, helium, ... }:

{
  imports = [
    # 1. THE NIXOS BRIDGE
    # This writes to /etc/chromium/policies/managed/
    helium.nixosModules.helium
  ];

  # 2. THE HOME MANAGER CONFIGURATION
  home-manager.users.${YOUR_USERNAME} = {
    imports = [
      helium.homeModules.helium
    ];

    programs.helium = {
      enable = true;
      defaultBrowser = true;

      # These flags get added to the wrapper
      extraFlags = [
        "--enable-features=HeliumMiddleClickAutoscroll"
      ];

      # These get merged into the policy file in /etc
      extraPolicies = {
        ExtensionInstallForcelist = [
          "ghmbeldphafepmbegfdlkpapadhbakde" # Proton Pass
          "ldgfbffkinooeloadekpmfoklnobpien" # Raindrop.io
          "mnjggcdmjocbbbhaepdhchncahnbgone" # SponsorBlock
        ];

        ExtensionSettings = {
          "ghmbeldphafepmbegfdlkpapadhbakde".toolbar_pin = "force_pinned";
          "ldgfbffkinooeloadekpmfoklnobpien".toolbar_pin = "force_pinned";
        };
      };

      # Preferences (Settings), look at the section below
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

| Option                 | Type               | Default                | Description                                        |
| :--------------------- | :----------------- | :--------------------- | :------------------------------------------------- |
| `enable`               | boolean            | `false`                | Whether to enable the Helium browser module.       |
| `package`              | package            | `self.packages.helium` | The helium package to use.                         |
| `extraFlags`           | list of strings    | `[]`                   | Command line arguments passed to the wrapper.      |
| `extraPolicies`        | attribute set      | `{}`                   | Raw Chromium policies to apply.                    |
| `preferences`          | attribute set      | `{}`                   | Json that will be merged into XDG Config.          |
| `defaultBrowser`       | boolean            | `false`                | Set Helium as the default browser in XDG mimeapps. |
| `nativeMessagingHosts` | list of packages   | `[]`                   | Native messaging host packages to expose to Helium. |

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
    bookmark_bar = {
      show_apps_shortcut = false;
      show_managed_bookmarks = false;
      show_on_all_tabs = false;
      show_tab_groups = false;
    };
    helium.browser.layout = 1;
  };
}
```

## Flake outputs

| Output                       | Description                     |
| ---------------------------- | ------------------------------- |
| `packages.<system>.helium`   | Helium browser package          |
| `apps.<system>.helium`       | `nix run` entry point           |
| `homeModules.helium`         | home-manager module             |
| `nixosModules.helium`        | nixos module                    |
| `devShells.<system>.default` | Shell with Helium available     |
| `checks.<system>.build`      | Build check (`nix flake check`) |
| `checks.<system>.module`     | NixOS/Home Manager module check |
