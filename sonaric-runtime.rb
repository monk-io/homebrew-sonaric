class SonaricRuntime < Formula
  desc "Sonaric Network Runtime: the runtime for the Sonaric Network daemon."
  homepage "https://sonaric.xyz"
  version "1.5.0"

  depends_on "podman"

  sha256 "dd9f6e10b434f9bce8bc304435762e74d23efab74076eb6fb68cf2dc4abfa0c5"
  url "https://raw.githubusercontent.com/monk-io/homebrew-sonaric/v1.5.0/sonaric-runtime.sh"

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
