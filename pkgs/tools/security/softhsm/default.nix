{ lib, stdenv, fetchurl, botan2, libobjc, Security }:

stdenv.mkDerivation rec {

  pname = "softhsm";
  version = "2.6.1";

  src = fetchurl {
    url = "https://dist.opendnssec.org/source/${pname}-${version}.tar.gz";
    hash = "sha256-YSSUcwVLzRgRUZ75qYmogKe9zDbTF8nCVFf8YU30dfI=";
  };

  configureFlags = [
    "--with-crypto-backend=botan"
    "--with-botan=${botan2}"
    "--sysconfdir=$out/etc"
    "--localstatedir=$out/var"
  ];

  propagatedBuildInputs = lib.optionals stdenv.isDarwin [ libobjc Security ];

  buildInputs = [ botan2 ];

  postInstall = "rm -rf $out/var";

  meta = with lib; {
    homepage = "https://www.opendnssec.org/softhsm";
    description = "Cryptographic store accessible through a PKCS #11 interface";
    longDescription =
      "\n      SoftHSM provides a software implementation of a generic\n      cryptographic device with a PKCS#11 interface, which is of\n      course especially useful in environments where a dedicated hardware\n      implementation of such a device - for instance a Hardware\n      Security Module (HSM) or smartcard - is not available.\n\n      SoftHSM follows the OASIS PKCS#11 standard, meaning it should be\n      able to work with many cryptographic products. SoftHSM is a\n      programme of The Commons Conservancy.\n    ";
    license = licenses.bsd2;
    maintainers = [ maintainers.leenaars ];
    platforms = platforms.unix;
  };
}
