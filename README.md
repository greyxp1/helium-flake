# helium-flake

> [!IMPORTANT]
> I only test `x86_64-linux`
>
> This was forked from: https://gitlab.com/AlexLov/helium-flake
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
    helium.url       = "github:greyp1/helium-flake";
  };

  outputs = { nixpkgs, home-manager, helium, ... }: {
    nixosConfigurations.mymachine = nixpkgs.lib.nixosSystem {
      modules = [
        home-manager.nixosModules.home-manager
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
> YOUT NEED BOTH THE NIXOS MODULE AND THE HOME-MANAGER MODULE FOR THE CONFIGURATION TO WORK CORRECTLY, BECAUSE THE CONFIGURATION IS WRITTEN IN `/etc/chromium/policies/managed/`

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

      extensions =  [
        # Example of a manual extension (React DevTools)
        # Look below, how to easily get these
        {
          id = "fmkadmapgofadopljbjfkapdkoienihi";
          hash = "sha256-mH9Fv78p6x6k7E0S9eYt+F7D1m/1K0K8j6hP1z9oUoY=";
        }
      ];

      # These flags get added to the wrapper
      extraFlags = [
        "--force-dark-mode"
        "--incognito"
      ];

      # These get merged into the policy file in /etc
      extraPolicies = {
        HomepageLocation = "https://start.duckduckgo.com";
        PasswordManagerEnabled = false;
        DeveloperToolsAvailability = 1; # Ensures 'Inspect Element' works
        ManagedBookmarks = [
          {
            toplevel_name = "Nix Ecosystem";
          }
          {
            url = "https://search.nixos.org/packages";
            name = "Nix Packages";
          }
        ];
      };

      # Preferences (Settings), look at the section below
      preferences = {
        browser.show_home_button = true;
        bookmark_bar.show_on_all_tabs = true;
      };
    };
  };
}
```

## Options Reference

The following options are available under `programs.helium`:

| Option           | Type               | Default                | Description                                        |
| :--------------- | :----------------- | :--------------------- | :------------------------------------------------- |
| `enable`         | boolean            | `false`                | Whether to enable the Helium browser module.       |
| `package`        | package            | `self.packages.helium` | The helium package to use.                         |
| `extensions`     | list of submodules | `[]`                   | List of extensions to install `{ id, hash }`.      |
| `extraFlags`     | list of strings    | `[]`                   | Command line arguments passed to the wrapper.      |
| `extraPolicies`  | attribute set      | `{}`                   | Raw Chromium policies to apply.                    |
| `preferences`    | attribute set      | `{}`                   | Json that will be merged into XDG Config.          |
| `defaultBrowser` | boolean            | `false`                | Set Helium as the default browser in XDG mimeapps. |

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

## Obtaining extensions

> [!WARNING]
> Be wary that if you are rate-limited that the file will be empty and the build will fail

Use the provided binary `prefetch-nix-extension` to obtain the nix code you need.

You can copy the IDs from the URL in the chrome web store:

```ascii
https://chromewebstore.google.com/detail/bitwarden-password-manage/nngceckbapebfimnlniiiahkandclblb
                                                                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ THIS PART
```

Example Usage:

```console
./prefetch-nix-extension.sh nngceckbapebfimnlniiiahkandclblb cjpalhdlnbpafiamejdnhcphjbkeiagm

# OUTPUT:
extensions = [
  { id = "nngceckbapebfimnlniiiahkandclblb"; hash = "sha256-XOVs2Tvay8hQ13SHz+728BDu2mMyQ0JxUuUI6FZ1NaM="; }
  { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; hash = "sha256-FIbmYVj8cmXce7Vq4h7d2nOjmk4RkCnABmC4y5NDyGk="; }
];
```

## Updating Helium

~~There is a Gitlab CI Pipeline which fetches from the upstream everyday at 20:00 UTC+2~~

## Flake outputs

| Output                       | Description                     |
| ---------------------------- | ------------------------------- |
| `packages.<system>.helium`   | Helium browser package          |
| `apps.<system>.helium`       | `nix run` entry point           |
| `homeModules.helium`         | home-manager module             |
| `nixosModules.helium`        | nixos module                    |
| `devShells.<system>.default` | Shell with Helium available     |
| `formatter.<system>`         | `nixfmt-tree` (`nix fmt`)       |
| `checks.<system>.build`      | Build check (`nix flake check`) |
