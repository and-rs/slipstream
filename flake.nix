{
  description = "Slipstream: LLMOps Engineering Environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      nixpkgs,
      rust-overlay,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs {
          inherit system overlays;
          config.allowUnfree = true;
        };

        rustToolchain = pkgs.rust-bin.stable.latest.default.override {
          extensions = [
            "rust-src"
            "rust-analyzer"
            "rustfmt"
            "clippy"
          ];
        };
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            rustToolchain
            pkg-config
            openssl
            terraform
            awscli2
            kubectl
            kubernetes-helm
            k9s
            opentelemetry-collector
            hey
            just
            fzf
            jq
          ];

          shellHook = ''
            echo -e "\n    vvvvvv"
            echo "--- LLMOps Engineering Environment ---"

            export REGION="us-west-2"

            export TF_VAR_target_region="$REGION"
            export AWS_DEFAULT_REGION="$REGION"
            export AWS_REGION="$REGION"
            aws configure set profile.nix-dev.region "$REGION"
            aws configure set profile.nix-dev.credential_process "aws configure export-credentials --profile default --format process"

            export AWS_PROFILE="nix-dev"
            echo "---- AWS profile: $AWS_PROFILE "
            echo "---- Current region: $REGION"

            # Helps rust-analyzer find the stdlib
            export RUST_SRC_PATH="${rustToolchain}/lib/rustlib/src/rust/library"

            aws --version
            terraform -version

            echo "--- Slipstream: semantic router for development LLMs ---"
            echo -e "    ^^^^^^^^^^\n"
          '';
        };
      }
    );
}
