{ config, ... }:
let
  inherit (config.vt-sway) customTarget;
in
{
  # custom target to bind services to
  systemd.user.targets."${customTarget.name}" = {
    Unit = {
      Description = customTarget.desc;
    };
  };

}
