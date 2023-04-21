pkgs:
{
  patched-sway = pkgs.sway.overrideAttrs (old:
    {
      patches =
        (
          old.patches or [ ]
        )
        ++
        [
          ./hide_cursor.patch
        ];
    }
  );
}
