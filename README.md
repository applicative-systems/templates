# Flake Templates

A collection of starter [Nix flake](https://nixos.wiki/wiki/Flakes) projects,
kept in one repository so they can be initialised with a single
`nix flake init` invocation.

## Available templates

| Name           | Description                                                                                                                                                                                                                                                                                                                                                           |
| -------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `default`      | Minimal starter flake for a multi-system project. Targets `x86_64-linux`, `aarch64-linux` and `aarch64-darwin` using the `eachSystem` style and tracks `nixos-unstable`. Ships with a placeholder `hello` package — swap it out for your own.                                                                                                                         |
| `docker-image` | Starter flake for [argunix](https://argunix.nix-consulting.net)-compatible OCI images. Linux-only (`x86_64-linux`, `aarch64-linux`). Defines the same `hello` image twice — once against glibc, once musl-static — to demonstrate how small Nix-built images can get. Comes with a NixOS-VM integration test (`docker load` + `docker run`), gated to `x86_64-linux`. |

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

## How templates are validated

Each template is wired up as a `path:` flake input on the top-level
`flake.nix` (with `inputs.nixpkgs.follows = "nixpkgs"` to dedupe). Its
default package is then re-exported under `checks.<system>.template-<name>`,
so `nix flake check` evaluates the template's outputs for every supported
system and builds the host-system one. End users initialising the template
via `nix flake init` are unaffected — they get a clean tree without any
parent lockfile baggage.

## Adding a new template

1. Create a new sub-directory containing a `flake.nix` (and any supporting
   files).
2. Register it in the top-level `flake.nix` under `templates.<name>` with a
   `path` and a `description`.
3. Wire it up for CI by adding a `template-<name>` input pointing at the
   sub-directory and a matching `checks.<system>.template-<name>` entry.
4. Document it in the table above.
