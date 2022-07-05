# Repo organization

* `flake.nix` – should only contain things that are key to the flake. No inline modules, no derivations.
* `modules/` – directory should contain a list of directories that encapsulate configurations of a single component. Should also contain `default.nix` file that imports subdirectories.
* `modules/$COMPONENT/` – directory that contains only $COMPONENT configuration.
* `lib/` – helper functions
* `overlay/` – additional derivations brought in by the flake
