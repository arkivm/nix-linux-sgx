{ lib
, stdenv
, fetchpatch
, fetchurl
, fetchFromGitHub
, autoconf
, automake
, binutils
, bison
, cmake
, file
, flex
, git
, gnum4
, libtool
, nasm
, ocaml
, ocamlPackages
, openssl
, perl
, python3
, texinfo
}:

stdenv.mkDerivation {
  pname = "sgx-sdk";
  version = "2.14a0";
  src = fetchFromGitHub {
    owner = "intel";
    repo = "linux-sgx";
    rev = "0cea078f17a24fb807e706409972d77f7a958db9";
    sha256 = "1cr2mkk459s270ng0yddgcryi0zc3dfmg9rmdrdh9mhy2mc1kx0g";
    fetchSubmodules = true;
  };
  dontConfigure = true;
  prePatch = ''
    patchShebangs ./linux/installer/bin/build-installpkg.sh \
      ./linux/installer/common/sdk/{createTarball.sh,install.sh}
  '';
  patches = [
    (fetchpatch {
      name = "replace-bin-cp-with-cp.patch";
      url = "https://github.com/intel/linux-sgx/commit/e0db5291d46d1c124980719d63829d65f89cf2c7.patch";
      sha256 = "0xwlpm1r4rl4anfhjkr6fgz0gcyhr0ng46fv8iw9hfsh891yqb7z";
    })
    (fetchpatch {
      name = "sgx_ippcp.h.patch";
      url = "https://github.com/intel/linux-sgx/commit/e5929083f8161a8e7404afc0577936003fbb9d0b.patch";
      sha256 = "12bgs9rxlq82hn5prl9qz2r4mwypink8hzdz4cki4k4cmkw961f5";
    })
    (fetchpatch {
      name = "ipp-crypto-makefile.patch";
      url = "https://github.com/intel/linux-sgx/commit/b1e1b2e9743c21460c7ab7637099818f656f9dd3.patch";
      sha256 = "14h6xkk7m89mkjc75r8parll8pmq493incq5snwswsbdzibrdi68";
    })
  ];
  nativeBuildInputs = [
    autoconf
    automake
    bison
    cmake
    libtool
    file
    flex
    git
    gnum4
    nasm
    ocaml
    ocamlPackages.ocamlbuild
    openssl
    perl
    texinfo
  ];
  buildInputs = [
    binutils
    python3
  ];
  preBuild = ''
    export BINUTILS_DIR=${binutils}/bin
  '';

  enableParallelBuilding = true;

  buildPhase = ''
    runHook preBuild

    cd external/ippcp_internal/
    make
    make clean
    make MITIGATION-CVE-2020-0551=LOAD
    make clean
    make MITIGATION-CVE-2020-0551=CF
    cd ../..

    make sdk_install_pkg

    runHook postBuild
  '';
  postBuild = ''
    patchShebangs ./linux/installer/bin/sgx_linux_x64_sdk_*.bin
  '';
  installPhase = ''
    echo -e 'no\n'$out | ./linux/installer/bin/sgx_linux_x64_sdk_*.bin
  '';

  meta = with lib; {
    description = "Intel SGX SDK for Linux built with IPP Crypto Library";
    homepage = "https://github.com/intel/linux-sgx";
    #maintainers = [ maintainers.sbellem ];
    platforms = platforms.linux;
    license = with licenses; [ bsd3 ];
  };
}
