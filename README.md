# Flake Templates

A collection of starter [Nix flake](https://nixos.wiki/wiki/Flakes) projects,
kept in one repository so they can be initialised with a single
`nix flake init` invocation.

## Available templates

| Name      | Description                                                                                                                                                                                                                                   |
| --------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `default` | Minimal starter flake for a multi-system project. Targets `x86_64-linux`, `aarch64-linux` and `aarch64-darwin` using the `eachSystem` style and tracks `nixos-unstable`. Ships with a placeholder `hello` package — swap it out for your own. |

## Usage

In an empty directory, initialise the default starter:

```sh
nix flake init -t github:applicative-systems/templates
```

Or pick a specific template by name:

```sh
nix flake init -t github:applicative-systems/templates#default
```

Then build it:

```sh
nix build
```

The default template ships with `pkgs.hello` purely as a placeholder so the
flake builds out of the box. Open `flake.nix` and replace it with your own
package, devShell, NixOS module, or whatever you're actually building.

To build for a specific system explicitly:

```sh
nix build .#packages.aarch64-darwin.default
nix build .#packages.x86_64-linux.default
nix build .#packages.aarch64-linux.default
```

## Formatting and linting

This repository is wired up with [treefmt-nix](https://github.com/numtide/treefmt-nix).
Format everything in place:

```sh
nix fmt
```

Check formatting without modifying files (also runs in CI via `nix flake check`):

```sh
nix flake check
```

The configured formatters/linters are `nixfmt`, `deadnix`, `statix`,
`prettier`, `shellcheck` and `shfmt`.

## Adding a new template

1. Create a new sub-directory containing a `flake.nix` (and any supporting
   files).
2. Register it in the top-level `flake.nix` under `templates.<name>` with a
   `path` and a `description`.
3. Document it in the table above.
