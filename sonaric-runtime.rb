class SonaricRuntime < Formula
  desc "Sonaric Network Runtime: the runtime for the Sonaric Network daemon."
  homepage "https://sonaric.xyz"
  version "1.9.6"

  depends_on "podman"

  sha256 "b1a86fd70ec07f4a1fb22ac9df5d7fa85ceeebbd2e159748af0bc1df52598150"
  url "https://raw.githubusercontent.com/monk-io/homebrew-sonaric/v1.9.6/sonaric-runtime.sh"

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
