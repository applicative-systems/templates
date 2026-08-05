# Flake Templates

A collection of starter [Nix flake](https://nixos.wiki/wiki/Flakes) projects,
kept in one repository so they can be initialised with a single
`nix flake init` invocation.

## Available templates

| Name           | Description                                                                                                                                                                                                                                                                                                                                                           |
| -------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `default`      | Minimal starter flake for a multi-system project. Targets `x86_64-linux`, `aarch64-linux` and `aarch64-darwin` using the `eachSystem` style and tracks `nixos-unstable`. Ships with a placeholder `hello` package — swap it out for your own.                                                                                                                         |
| `docker-image` | Starter flake for [argunix](https://argunix.nix-consulting.net)-compatible OCI images. Linux-only (`x86_64-linux`, `aarch64-linux`). Defines the same `hello` image twice — once against glibc, once musl-static — to demonstrate how small Nix-built images can get. Comes with a NixOS-VM integration test (`docker load` + `docker run`), gated to `x86_64-linux`. |
| `minimal`      | Smallest possible starter flake. Instead of an explicit system list, it maps over `nixpkgs.legacyPackages`, so it exposes its `hello` placeholder package for every system nixpkgs supports.                                                                                                                                                                          |

## Which template should I use?

If you are new to flakes, the choice boils down to `minimal` vs. `default`:

**Start with `minimal`.** If all you need is to expose a few packages and
possibly a devShell, this is the right template for most cases. It takes
`nixpkgs` as it comes — no overlays, no nixpkgs configuration — and simply maps
over `nixpkgs.legacyPackages`, which already provides a ready-made package set
for every system. Resist the urge to reach for
[flake-utils](https://github.com/numtide/flake-utils) or
[flake-parts](https://github.com/hercules-ci/flake-parts): these libraries are
good, but they are overhead you don't need at this stage.

```sh
nix flake init -t github:applicative-systems/templates#minimal
```

**Switch to `default` when you need to configure nixpkgs.** As soon as you
want to change the nixpkgs config (e.g. `allowUnfree`) or apply overlays, you
have to call `import nixpkgs { ... }` yourself — `legacyPackages` won't cut it
anymore. The `default` template does exactly that with a small hand-rolled
`eachSystem` helper. This is deliberately better than pulling in flake-utils
for the same job:

- it avoids yet another flake input, and
- it is transparent about the supported architectures — the system list sits
  right at the top of your `flake.nix`, so nobody has to search through a
  library to find out where it is defined.

The handful of extra lines of code is a better deal than an additional flake
input whose only job is supporting multiple output systems.

```sh
nix flake init -t github:applicative-systems/templates#default
```

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

This repository is wired up with [treefmt](https://github.com/numtide/treefmt),
configured directly in `flake.nix` via `pkgs.treefmt.withConfig` (no extra
flake input needed). Format everything in place:

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
