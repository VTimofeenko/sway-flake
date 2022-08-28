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
            "CTRL_L-a" = "home";
            "CTRL_L-e" = "end";
            /* Same, but with selection */
            "CTRL_L-Shift-a" = "Shift-home";
            "CTRL_L-Shift-e" = "Shift-end";
            # Select all
            "ALT_L-a" = "c-a";
            # Copy
            "ALT_L-c" = "c-c";
            # Paste
            "ALT_L-v" = "c-v";
            # Cut
            "ALT_L-x" = "c-x";
            # Undo
            "ALT_L-z" = "c-z";
          };
        }
        {
          name = "Right alt + hjkl = arrows";
          remap = {
            "ALT_R-h" = "Left";
            "ALT_R-j" = "Down";
            "ALT_R-k" = "Up";
            "ALT_R-l" = "Right";
            "ALT_R-u" = "Pageup";
            "ALT_R-d" = "Pagedown";
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
