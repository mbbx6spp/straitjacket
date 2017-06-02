{ bootpkgs ? import <nixpkgs> {}
, ruby ? bootpkgs.ruby
,...
}:
let
  pkgs = import (bootpkgs.fetchgit (import ./z/etc/versions/nixpkgs.nix)) {};
  inherit (pkgs) stdenv callPackage lib bundler bundlerEnv;

  appRoot = builtins.toPath ./.;
  bundlePath = builtins.toPath "${appRoot}/vendor";

  targetRuby = pkgs.ruby_2_4;
  myBundler = bundler.override { ruby = targetRuby; };
  myBundix = bootpkgs.fetchgit (import ./z/etc/versions/bundix.nix);
  myBundlerEnv = bundlerEnv.override { ruby = targetRuby; bundler = myBundler; };

  sj = callPackage ./default.nix { bundlerEnv = myBundlerEnv; };
in stdenv.mkDerivation {
  name = "straitjacket-devenv";
  src = ./.;

  buildInputs = with pkgs; [
    myBundix
    myBundler
    targetRuby
  ];
}

