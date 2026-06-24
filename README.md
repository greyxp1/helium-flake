## Quick start

```sh
nix run github:greyxp1/helium-flake
```

## Usage

Add the flake to your inputs:

```nix
helium.url = "github:greyxp1/helium-flake";
```

## Options

- `enable`: install and configure Helium.
- `defaultBrowser`: register Helium as the default browser for HTML, HTTP, and HTTPS.
- `flags`: extra command-line [flags](helium://flags/) passed to Helium.
- `preferences`: Chromium [preference keys](helium://prefs-internals/) merged into `~/.config/net.imput.helium/Default/Preferences`.
- `extensions`: Chrome [Web Store](https://chromewebstore.google.com/) extensions to force-install.
- `extraPolicies`: Chromium policy values from [`helium://policy/`](helium://policy/) written to managed policy files.
- `nativeMessagingHosts`: native messaging host packages to expose to Helium.
- `package`: override the Helium package used by the module.

### Extensions

Each extension needs an `id`. Set `pin = true` to force-pin it to the toolbar.

```nix
programs.helium.extensions = {
  darkReader.id = "eimadpbcbfnmbkopoojfekhnkhdbieeh";

  protonPass = {
    id = "ghmbeldphafepmbegfdlkpapadhbakde";
    pin = true;
  };
};
```

## Example configuration

```nix
{ helium, ... }:

{
  imports = [helium.nixosModules.helium];
  home-manager.users.${YOUR_USERNAME} = {
    programs.helium = {
      enable = true;
      defaultBrowser = true;
      nativeMessagingHosts = [pkgs.keepassxc];

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

## Credits

- Most of the original flake, package, NixOS module, and Home Manager module code was written by [ntgn's helium-flake](https://gitlab.com/ntgn/helium-flake).
- The `nativeMessagingHosts` support was added by [AlexLov's fork](https://gitlab.com/AlexLov/helium-flake).
- This fork contains my changes on top of their work.
