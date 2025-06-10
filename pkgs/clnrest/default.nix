{
  lib,
  rustPlatform,
  clightning,
  unzip,
  protobuf,
}:
rustPlatform.buildRustPackage rec {
  pname = "clnrest";
  version = "0.2.0";

  inherit (clightning) src;

  cargoHash = "sha256-rXOpRNzIDohfvn3n1xEhc/C1pCpzgfFXHjob7/qOeXM=";

  depsExtraArgs = {
    nativeBuildInputs = [ unzip ];
    # Don't run `configure` of the main project build
    dontConfigure = true;
  };

  nativeBuildInputs = [
    # For unpacking the src
    unzip
  ];

  cargoBuildFlags = [ "--package clnrest" ];

  nativeCheckInputs = [
    # Required by lightning/cln-grpc/build.rs
    protobuf
  ];

  meta = with lib; {
    description = "REST plugin for clightning";
    homepage = "https://github.com/ElementsProject/lightning/tree/master/plugins/rest-plugin";
    license = licenses.mit;
    maintainers = with maintainers; [
      erikarvstedt
    ];
    mainProgram = "clnrest";
  };
}
