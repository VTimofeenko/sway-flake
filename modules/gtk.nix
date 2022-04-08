{ pkgs, lib, ... }:

{
  /* Taken from https://www.reddit.com/r/NixOS/comments/nxnswt/comment/h1skv8w/?utm_source=share&utm_medium=web2x&context=3 */
  gtk.enable = true;
  /* gtk.font.name = "Noto Sans"; */
  /* gtk.font.package = pkgs.noto-fonts; */
  gtk.theme.name = "Materia";
  gtk.theme.package = pkgs.materia-theme;
  gtk.iconTheme.name = "Papirus-Dark-Maia";
  gtk.iconTheme.package = pkgs.papirus-maia-icon-theme;
  /* TODO gtk.cursorTheme is only on unstable :( */
  home.packages = [ pkgs.quintom-cursor-theme ];
  gtk.gtk3.extraConfig = {
    gtk-application-prefer-dark-theme = true;
    gtk-icon-theme-name   = "Papirus-Dark-Maia";
    gtk-cursor-theme-name = "Quintom_Ink";
  };
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      cursor-theme = "Quintom_Ink";
    };
  };
  xdg.systemDirs.data = [
    "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}"
    "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}"
  ];

}
