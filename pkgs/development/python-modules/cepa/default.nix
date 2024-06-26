{ lib
, buildPythonPackage
, fetchpatch
, fetchPypi
, python
, mock
}:

buildPythonPackage rec {
  pname = "cepa";
  version = "1.8.4";
  format = "setuptools";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-P7xwGsP8ic1/abxYptDXNbAU+kC2Hiwu/Tge0g21ipY=";
  };

  patches = [
    (fetchpatch {
      name = "python-3.11-compatibility.patch";
      url = "https://github.com/onionshare/cepa/commit/0bf9aee7151e65594c532826bb04636e1d80fb6f.patch";
      hash = "sha256-roSt9N5OvnOOxKZUee86zGXt0AsZCcbBdV2cLz1MB2k=";
    })
  ];

  postPatch = ''
    rm test/unit/installation.py
    sed -i "/test.unit.installation/d" test/settings.cfg
    # https://github.com/torproject/stem/issues/56
    sed -i '/MOCK_VERSION/d' run_tests.py
  '';

  nativeCheckInputs = [ mock ];

  checkPhase = ''
    touch .gitignore
    ${python.interpreter} run_tests.py -u
  '';

  meta = with lib; {
    description = "Controller library that allows applications to interact with Tor";
    mainProgram = "tor-prompt";
    homepage = "https://github.com/onionshare/cepa";
    license = licenses.lgpl3Only;
    maintainers = with maintainers; [ bbjubjub ];
  };
}
