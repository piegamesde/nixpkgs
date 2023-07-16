{
  lib,
  version,
  buildPlatform,
  hostPlatform,
  targetPlatform,
  gnat-bootstrap ? null,
  langAda ? false,
  langJava ? false,
  langJit ? false,
  langGo,
  crossStageStatic,
  enableMultilib,
}:

assert langJava -> lib.versionOlder version "7";
assert langAda -> gnat-bootstrap != null;
let
  needsLib =
    (
      lib.versionOlder version "7" && (langJava || langGo)
    )
    || (
      lib.versions.major version == "4"
      && lib.versions.minor version == "9"
      && targetPlatform.isDarwin
    )
    ;
in
lib.optionalString (hostPlatform.isSunOS && hostPlatform.is64bit) ''
  export NIX_LDFLAGS=`echo $NIX_LDFLAGS | sed -e s~$prefix/lib~$prefix/lib/amd64~g`
  export LDFLAGS_FOR_TARGET="-Wl,-rpath,$prefix/lib/amd64 $LDFLAGS_FOR_TARGET"
  export CXXFLAGS_FOR_TARGET="-Wl,-rpath,$prefix/lib/amd64 $CXXFLAGS_FOR_TARGET"
  export CFLAGS_FOR_TARGET="-Wl,-rpath,$prefix/lib/amd64 $CFLAGS_FOR_TARGET"
''

# On mips platforms, gcc follows the IRIX naming convention:
#
#  $PREFIX/lib   = mips32
#  $PREFIX/lib32 = mips64n32
#  $PREFIX/lib64 = mips64
#
+ lib.optionalString needsLib ''
  export lib=$out;
''

# On mips platforms, gcc follows the IRIX naming convention:
#
#  $PREFIX/lib   = mips32
#  $PREFIX/lib32 = mips64n32
#  $PREFIX/lib64 = mips64
#
+ lib.optionalString langAda ''
  export PATH=${gnat-bootstrap}/bin:$PATH
''

# On mips platforms, gcc follows the IRIX naming convention:
#
#  $PREFIX/lib   = mips32
#  $PREFIX/lib32 = mips64n32
#  $PREFIX/lib64 = mips64
#
+ lib.optionalString
  (
    langAda
    && buildPlatform == hostPlatform
    && hostPlatform == targetPlatform
    && targetPlatform.isx86_64
    && targetPlatform.isDarwin
  )
  ''
    export AS_FOR_BUILD=${gnat-bootstrap}/bin/as
    export AS_FOR_TARGET=${gnat-bootstrap}/bin/gas
  ''

# On mips platforms, gcc follows the IRIX naming convention:
#
#  $PREFIX/lib   = mips32
#  $PREFIX/lib32 = mips64n32
#  $PREFIX/lib64 = mips64
#
+ lib.optionalString (hostPlatform.isDarwin) ''
  export ac_cv_func_aligned_alloc=no
''

# On mips platforms, gcc follows the IRIX naming convention:
#
#  $PREFIX/lib   = mips32
#  $PREFIX/lib32 = mips64n32
#  $PREFIX/lib64 = mips64
#
+ lib.optionalString (hostPlatform.isDarwin && langJit) ''
  export STRIP='strip -x'
''

# On mips platforms, gcc follows the IRIX naming convention:
#
#  $PREFIX/lib   = mips32
#  $PREFIX/lib32 = mips64n32
#  $PREFIX/lib64 = mips64
#
+ lib.optionalString
  (
    targetPlatform.config == hostPlatform.config
    && targetPlatform != hostPlatform
  )
  ''
    substituteInPlace configure --replace is_cross_compiler=no is_cross_compiler=yes
  ''

# On mips platforms, gcc follows the IRIX naming convention:
#
#  $PREFIX/lib   = mips32
#  $PREFIX/lib32 = mips64n32
#  $PREFIX/lib64 = mips64
#
+ lib.optionalString (targetPlatform != hostPlatform && crossStageStatic) ''
  export inhibit_libc=true
''

# On mips platforms, gcc follows the IRIX naming convention:
#
#  $PREFIX/lib   = mips32
#  $PREFIX/lib32 = mips64n32
#  $PREFIX/lib64 = mips64
#
+ lib.optionalString
  (!enableMultilib && hostPlatform.is64bit && !hostPlatform.isMips64n32)
  ''
    export linkLib64toLib=1
  ''

# On mips platforms, gcc follows the IRIX naming convention:
#
#  $PREFIX/lib   = mips32
#  $PREFIX/lib32 = mips64n32
#  $PREFIX/lib64 = mips64
#
+ lib.optionalString (!enableMultilib && targetPlatform.isMips64n32) ''
  export linkLib32toLib=1
''
