class SonaricRuntime < Formula
  desc "Sonaric Network Runtime: the runtime for the Sonaric Network daemon."
  homepage "https://sonaric.xyz"
  version "1.7.4"

  depends_on "podman"

  sha256 "5810eab4ff9e6e091563e366e9dd606dc1eec36ea44cc3dac81ff0482e96d045"
  url "https://raw.githubusercontent.com/monk-io/homebrew-sonaric/v1.7.4/sonaric-runtime.sh"

  def install
    bin.install "sonaric-runtime.sh" => "sonaric-runtime"
  end

  def caveats; <<~EOS
    Sonaric runtime will be started automatically via brew services
      brew services info sonaric-runtime
    EOS
  end

  service do
    run [opt_bin/"sonaric-runtime"]
    keep_alive true
  end
end
