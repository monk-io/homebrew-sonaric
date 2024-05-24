class SonaricRuntime < Formula
  desc "Sonaric Network Runtime: the runtime for the Sonaric Network daemon."
  homepage "https://sonaric.xyz"
  version "0.0.1"

  depends_on "podman"

  sha256 "55a830fbd30bf7d8a9da8b614667cd19c7a0946fbccdb19bde3f4fa8a419b56f"
  url "https://raw.githubusercontent.com/monk-io/homebrew-sonaric/HEAD/sonaric-runtime.sh"

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
