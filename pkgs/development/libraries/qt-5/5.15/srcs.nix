{ lib, fetchgit, fetchFromGitHub }:

let
  version = "5.15.8";
  overrides = {};

  mk = name: args:
    let
      override = overrides.${name} or {};
    in
    {
      version = override.version or version;
      src = override.src or
        fetchgit {
          inherit (args) url rev sha256;
          fetchLFS = false;
          fetchSubmodules = true;
          deepClone = false;
          leaveDotGit = false;
        };
    };
in
lib.mapAttrs mk (lib.importJSON ./srcs-generated.json)
// {
  # qtwebkit does not have an official release tarball on the qt mirror and is
  # mostly maintained by the community.
  qtwebkit = rec {
    src = fetchFromGitHub {
      owner = "qt";
      repo = "qtwebkit";
      rev = "v${version}";
      sha256 = "0x8rng96h19xirn7qkz3lydal6v4vn00bcl0s3brz36dfs0z8wpg";
    };
    version = "5.212.0-alpha4";
  };

  # qtsystems has no official releases
  qtsystems = {
    version = "unstable-2019-01-03";
    src = fetchFromGitHub {
      owner = "qt";
      repo = "qtsystems";
      rev = "e3332ee38d27a134cef6621fdaf36687af1b6f4a";
      hash = "sha256-P8MJgWiDDBCYo+icbNva0LODy0W+bmQTS87ggacuMP0=";
    };
  };

  catapult = fetchgit {
    url = "https://chromium.googlesource.com/catapult";
    rev = "5eedfe23148a234211ba477f76fc2ea2e8529189";
    hash = "sha256-LPfBCEB5tJOljXpptsNk0sHGtJf/wIRL7fccN79Nh6o=";
  };

  qtwebengine =
    let
      branchName = "5.15.12";
      rev = "v${branchName}-lts";
    in
    {
      version = branchName;

      src = fetchgit {
        url = "https://github.com/qt/qtwebengine.git";
        sha256 = "sha256-8EQqSvxw9rqf+64CIbcCb1VXhNx1GNC8eDIgLyYDyvk=";
        inherit rev branchName;
        fetchSubmodules = true;
        leaveDotGit = true;
        name = "qtwebengine-${lib.substring 0 8 rev}.tar.gz";
        postFetch = ''
          # remove submodule .git directory
          rm -rf "$out/src/3rdparty/.git"

          # compress to not exceed the 2GB output limit
          # try to make a deterministic tarball
          tar -I 'gzip -n' \
            --sort=name \
            --mtime=1970-01-01 \
            --owner=root --group=root \
            --numeric-owner --mode=go=rX,u+rw,a-s \
            --transform='s@^@source/@' \
            -cf temp  -C "$out" .
          rm -r "$out"
          mv temp "$out"
        '';
      };
    };
}
