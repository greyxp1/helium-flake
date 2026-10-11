# helium-flake

A rewrite of [ntgn's helium-flake](https://gitlab.com/ntgn/helium-flake).

## Quick start

```sh
nix run github:greyxp1/helium-flake
```

## Installation

Add Helium to your flake inputs:

```nix
inputs.helium.url = "github:greyxp1/helium-flake";
```

Import and enable the module in your NixOS or Home Manager configuration:

```nix
{inputs, ...}: {
  # Use homeModules.helium for Home Manager.
  imports = [inputs.helium.nixosModules.helium];
  programs.helium.enable = true;
}
```

## Options

- `enable`: install Helium.
- `package`: Helium package to configure.
- `defaultBrowser`: register Helium as the default browser.
- `flags`: extra command-line flags from `helium://flags/` passed to Helium.
- `preferences`: options you'd configure in the `Settings` menu. A list of all preferences can be found in `helium://prefs-internals/`.
- `extensions`: store extensions, unpacked directories, and built-in extension pins.
- `extraPolicies`: Chromium policy values from `helium://policy/` written to managed policy files.

### Default configuration

```nix
programs.helium = {
  extraPolicies = {
    RestoreOnStartup = 1;
    HighEfficiencyModeEnabled = true;
    MemorySaverModeSavings = 2;
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
        rounded_frame = false;
        show_vertical_tabs_collapse_button = false;
      };
    };
  };
};
```

### Extensions

Use `id` for store extensions or `path` for unpacked extensions. Set `pin = true` with an `id` to force-pin an extension. Built-in extensions use `install = false`.

```nix
programs.helium.extensions = {
  darkReader = {
    id = "eimadpbcbfnmbkopoojfekhnkhdbieeh";
    pin = true;
  };
  equicord.path = config.programs.nixcord.browser.finalPackage;
  ublock = {
    id = "blockjmkbacgjkknlgpkjjiijinjdanf";
    install = false;
    pin = true;
  };
};
```

## Example configuration

```nix
programs.helium = {
  enable = true;
  defaultBrowser = true;
  flags = ["--enable-features=HeliumMiddleClickAutoscroll"];

  extraPolicies = {
    DefaultSearchProviderEnabled = true;
    DefaultSearchProviderName = "Google";
    DefaultSearchProviderSearchURL = "https://www.google.com/search?q={searchTerms}";
    DefaultSearchProviderSuggestURL = "https://www.google.com/complete/search?output=chrome&q={searchTerms}";
  };

  preferences = {
    helium.browser = {
      show_back_button = false;
      show_reload_button = false;
      vertical_right_aligned = true;
    };

    browser = {
      show_forward_button = false;
      custom_chrome_frame = false;
    };
  };

  extensions = {
    sponsorBlock.id = "mnjggcdmjocbbbhaepdhchncahnbgone";
    deArrow.id = "enamippconapkdmgfgjchkhakpfinmaj";
    controlPanel.id = "lodcanccmfbpjjpnngindkkmiehimile";
    re-start.id = "fdodcmjeojbmcgmhcgcelffcekhicnop";

    ublock = {
      id = "blockjmkbacgjkknlgpkjjiijinjdanf";
      install = false;
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
}
```
