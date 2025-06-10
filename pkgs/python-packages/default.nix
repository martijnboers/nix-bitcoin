nbPkgs: python3:
rec {
  pyPkgsOverrides = self: super: let
    inherit (self) callPackage;
    clightningPkg = pkg: callPackage pkg { inherit (nbPkgs.pinned) clightning; };
  in
    {
      txzmq = callPackage ./txzmq {};
      pyln-client = clightningPkg ./pyln-client;
      pyln-proto = clightningPkg ./pyln-proto;
      pyln-bolt7 = clightningPkg ./pyln-bolt7;
      pylightning = clightningPkg ./pylightning;
      # TODO: Remove after 2026-05-09
      clnrest = throw "`nbPython3Packages.clnrest` has been replaced with nix-bitcoin pkg `clnrest` (Rust rewrite)";

      # Packages only used by joinmarket
      bencoderpyx = callPackage ./bencoderpyx {};
      chromalog = callPackage ./chromalog {};
      python-bitcointx = callPackage ./python-bitcointx { inherit (self.pkgs) secp256k1; };
      runes = callPackage ./runes {};
      sha256 = callPackage ./sha256 {};

      joinmarket = callPackage ./joinmarket { inherit (nbPkgs.joinmarket) version src; };

      ## Specific versions of packages that already exist in nixpkgs

      # autobahn 20.12.3, required by joinmarketclient
      autobahn = callPackage ./specific-versions/autobahn.nix {};
      # coincurve 20, required by pyln-proto.
      coincurve = callPackage ./specific-versions/coincurve_20 {};
      # scikit-build-core 0_10, required by coincurve.
      scikit-build-core = callPackage ./specific-versions/scikit-build-core_0_10 {};
    };

  nbPython3Packages = (python3.override {
    packageOverrides = pyPkgsOverrides;
  }).pkgs;

  nbPython3PackagesJoinmarket = nbPython3Packages;
}
