{
  lib,
  writeText,
  writeCBin,
  writeShellScript,
  makeWrapper,
  runCommand,
  which,
  ...
}:

let
  # Testfiles
  foofile = writeText "foofile" "foo";
  barfile = writeText "barfile" "bar";

  # Wrapped binaries
  wrappedArgv0 = writeCBin "wrapped-argv0" ''
    #include <stdio.h>
    #include <stdlib.h>

    void main(int argc, char** argv) {
      printf("argv0=%s", argv[0]);
      exit(0);
    }
  '';
  wrappedBinaryVar = writeShellScript "wrapped-var" ''
    echo "VAR=$VAR"
  '';
  wrappedBinaryArgs = writeShellScript "wrapped-args" ''
    echo "$@"
  '';

  mkWrapperBinary =
    {
      name,
      args,
      wrapped ? wrappedBinaryVar
    }:
    runCommand name { nativeBuildInputs = [ makeWrapper ]; } ''
      mkdir -p $out/bin
      makeWrapper "${wrapped}" "$out/bin/${name}" ${lib.escapeShellArgs args}
    ''
    ;

  mkTest =
    cmd: toExpect: ''
      output="$(${cmd})"
      if [[ "$output" != '${toExpect}' ]]; then
        echo "test failed: the output of ${cmd} was '$output', expected '${toExpect}'"
        echo "the wrapper contents:"
        for i in ${cmd}; do
          if [[ $i =~ ^test- ]]; then
            cat $(which $i)
          fi
        done
        exit 1
      fi
    ''
    ;
in
runCommand "make-wrapper-test"
{
  nativeBuildInputs = [
    which
    (mkWrapperBinary {
      name = "test-argv0";
      args = [
        "--argv0"
        "foo"
      ];
      wrapped = "${wrappedArgv0}/bin/wrapped-argv0";
    })
    (mkWrapperBinary {
      name = "test-set";
      args = [
        "--set"
        "VAR"
        "abc"
      ];
    })
    (mkWrapperBinary {
      name = "test-set-default";
      args = [
        "--set-default"
        "VAR"
        "abc"
      ];
    })
    (mkWrapperBinary {
      name = "test-unset";
      args = [
        "--unset"
        "VAR"
      ];
    })
    (mkWrapperBinary {
      name = "test-run";
      args = [
        "--run"
        "echo bar"
      ];
    })
    (mkWrapperBinary {
      name = "test-run-and-set";
      args = [
        "--run"
        "export VAR=foo"
        "--set"
        "VAR"
        "bar"
      ];
    })
    (mkWrapperBinary {
      name = "test-args";
      args = [
        "--add-flags"
        "abc"
        "--append-flags"
        "xyz"
      ];
      wrapped = wrappedBinaryArgs;
    })
    (mkWrapperBinary {
      name = "test-prefix";
      args = [
        "--prefix"
        "VAR"
        ":"
        "abc"
      ];
    })
    (mkWrapperBinary {
      name = "test-prefix-noglob";
      args = [
        "--prefix"
        "VAR"
        ":"
        "./*"
      ];
    })
    (mkWrapperBinary {
      name = "test-suffix";
      args = [
        "--suffix"
        "VAR"
        ":"
        "abc"
      ];
    })
    (mkWrapperBinary {
      name = "test-prefix-and-suffix";
      args = [
        "--prefix"
        "VAR"
        ":"
        "foo"
        "--suffix"
        "VAR"
        ":"
        "bar"
      ];
    })
    (mkWrapperBinary {
      name = "test-prefix-multi";
      args = [
        "--prefix"
        "VAR"
        ":"
        "abc:foo:foo"
      ];
    })
    (mkWrapperBinary {
      name = "test-suffix-each";
      args = [
        "--suffix-each"
        "VAR"
        ":"
        "foo bar:def"
      ];
    })
    (mkWrapperBinary {
      name = "test-prefix-each";
      args = [
        "--prefix-each"
        "VAR"
        ":"
        "foo bar:def"
      ];
    })
    (mkWrapperBinary {
      name = "test-suffix-contents";
      args = [
        "--suffix-contents"
        "VAR"
        ":"
        "${foofile} ${barfile}"
      ];
    })
    (mkWrapperBinary {
      name = "test-prefix-contents";
      args = [
        "--prefix-contents"
        "VAR"
        ":"
        "${foofile} ${barfile}"
      ];
    })
  ];
}
(
  # --argv0 works
    mkTest
    "test-argv0"
    "argv0=foo"
  + mkTest "test-set" "VAR=abc"
  + mkTest "VAR=foo test-set" "VAR=abc"
  + mkTest "test-set-default" "VAR=abc"
  + mkTest "VAR=foo test-set-default" "VAR=foo"
  + mkTest "VAR=foo test-unset" "VAR="
  + mkTest "test-args" "abc xyz"
  + mkTest "test-args foo" "abc foo xyz"
  + mkTest "test-run" ''
    bar
    VAR=''
  + mkTest "test-run-and-set" "VAR=bar"
  + mkTest "VAR=foo test-prefix" "VAR=abc:foo"
  + mkTest "test-prefix" "VAR=abc"
  + mkTest "VAR=abc test-prefix" "VAR=abc"
  + mkTest "VAR=foo:abc test-prefix" "VAR=abc:foo"
  + mkTest "VAR=abc:foo:bar test-prefix-multi" "VAR=abc:foo:bar"
  + mkTest "VAR=test:abcde:test test-prefix" "VAR=abc:test:abcde:test"
  + mkTest "test-prefix" "VAR=abc"
  + mkTest "VAR=f?oo test-prefix-noglob" "VAR=./*:f?oo"
  + mkTest "VAR=foo test-suffix" "VAR=foo:abc"
  + mkTest "test-suffix" "VAR=abc"
  + mkTest "VAR=abc test-suffix" "VAR=abc"
  + mkTest "VAR=abc:foo test-suffix" "VAR=abc:foo"
  + mkTest "VAR=abc test-prefix-and-suffix" "VAR=foo:abc:bar"
  + mkTest "VAR=abc test-suffix-each" "VAR=abc:foo:bar:def"
  + mkTest "VAR=abc test-prefix-each" "VAR=bar:def:foo:abc"
  + mkTest "VAR=abc test-suffix-contents" "VAR=abc:foo:bar"
  + mkTest "VAR=abc test-prefix-contents" "VAR=bar:foo:abc"
  + "touch $out"
)
