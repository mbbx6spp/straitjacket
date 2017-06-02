{ bundlerEnv
, lib
, pkgs
, ruby ? pkgs.ruby_2_4 }:
bundlerEnv {
  inherit ruby;

  name = "straightjacket-0.9";
  gemfile = ./Gemfile;
  lockfile = ./Gemfile.lock;
  meta = with lib; {
    description = "Write maintainable, composable software.";
    homepage = "https://github.com/dailykos/straitjacket";
    license = licenses.MIT;
    platforms = platforms.unix;
  };
}

