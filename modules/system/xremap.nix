{ pkgs, lib, ... }:
let
  username = "spacecadet";
in
{
  services.xremap = {
    withSway = true;
    userName = username;
    deviceName = "AT Translated Set 2 keyboard";
    config = {
      modmap = [
        {
          # Globally remap CapsLock to Esc
          name = "Global";
          remap = { "CapsLock" = "Esc"; };
        }
      ];
      keymap = [
        {
          name = "Emacs-like shortcuts";
          application = {
            "not" = "kitty";
          };
          remap = {
            "C-a" = "home";
            "C-e" = "end";
            /* Same, but with selection */
            "C-Shift-a" = "Shift-home";
            "C-Shift-e" = "Shift-end";
            # Select all
            "M-a" = "c-a";
            # Copy
            "M-c" = "c-c";
            # Paste
            "M-v" = "c-v";
            "M-z" = "c-z";
          };
        }
        {
          name = "Right alt + hjkl = arrows";
          remap = {
            "M_R-h" = "Left";
            "M_R-j" = "Down";
            "M_R-k" = "Up";
            "M_R-l" = "Right";
            "M_R-u" = "Pageup";
            "M_R-d" = "Pagedown";
          };
        }
        {
          name = "Make kitty obey alt-c alt-v";
          application = {
            "only" = "kitty";
          };
          remap = {
            # Copy
            "M-c" = "C-Shift-c";
            # Paste
            "M-v" = "C-Shift-v";
          };
        }
        {
          name = "Brave fix incognito mode";
          application = {
            "only" = "Brave-browser";
          };
          remap = {
            "C-Shift-p" = "C-Shift-n";
          };

        }
      ];
    };
  };
  /*
    Needed for restart of system xremap after login as user
  */
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
        if (action.id == "org.freedesktop.systemd1.manage-units" &&
            action.lookup("unit") == "xremap.service" &&
            subject.user == "${username}") {
        return polkit.Result.YES;
        }
        });
  '';
}
