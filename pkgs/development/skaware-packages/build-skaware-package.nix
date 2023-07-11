{
  lib,
  stdenv,
  cleanPackaging,
  fetchurl,
}:
{
  # : string
  pname,
  # : string
  version,
  # : string
  sha256,
  # : string
  description,
  # : list Platform
  platforms ? lib.platforms.all,
  # : list string
  outputs ? [
    "bin"
    "lib"
    "dev"
    "doc"
    "out"
  ],
  # TODO(Profpatsch): automatically infer most of these
  # : list string
  configureFlags,
  # : string
  postConfigure ? null,
  # mostly for moving and deleting files from the build directory
  # : lines
  postInstall,
  # : list Maintainer
  maintainers ? [ ],
  # : passthru arguments (e.g. tests)
  passthru ? { },

}:

let

  # File globs that can always be deleted
  commonNoiseFiles = [
    ".gitignore"
    "Makefile"
    "INSTALL"
    "configure"
    "patch-for-solaris"
    "src/**/*"
    "tools/**/*"
    "package/**/*"
    "config.mak"
  ];

  # File globs that should be moved to $doc
  commonMetaFiles = [
    "COPYING"
    "AUTHORS"
    "NEWS"
    "CHANGELOG"
    "README"
    "README.*"
    "DCO"
    "CONTRIBUTING"
  ];
in
stdenv.mkDerivation {
  inherit pname version;

  src = fetchurl {
    url = "https://skarnet.org/software/${pname}/${pname}-${version}.tar.gz";
    inherit sha256;
  };

  inherit outputs;

  dontDisableStatic = true;
  enableParallelBuilding = true;

  configureFlags =
    configureFlags
    ++ [
      "--enable-absolute-paths"
      # We assume every nix-based cross target has urandom.
      # This might not hold for e.g. BSD.
      "--with-sysdep-devurandom=yes"
      (
        if stdenv.isDarwin then
          "--disable-shared"
        else
          "--enable-shared"
      )
    ]
    ++ (lib.optional stdenv.isDarwin "--build=${stdenv.hostPlatform.system}")
    ;

  inherit postConfigure;

  makeFlags = lib.optionals stdenv.cc.isClang [
    "AR=${stdenv.cc.targetPrefix}ar"
    "RANLIB=${stdenv.cc.targetPrefix}ranlib"
  ];

  # TODO(Profpatsch): ensure that there is always a $doc output!
  postInstall = ''
    echo "Cleaning & moving common files"
    ${
      cleanPackaging.commonFileActions {
        noiseFiles = commonNoiseFiles;
        docFiles = commonMetaFiles;
      }
    } $doc/share/doc/${pname}

    ${postInstall}
  '';

  postFixup = ''
    ${cleanPackaging.checkForRemainingFiles}
  '';

  meta = {
    homepage = "https://skarnet.org/software/${pname}/";
    inherit description platforms;
    license = lib.licenses.isc;
    maintainers = with lib.maintainers;
      [
        pmahoney
        Profpatsch
        qyliss
      ]
      ++ maintainers;
  };

  inherit passthru;
}
