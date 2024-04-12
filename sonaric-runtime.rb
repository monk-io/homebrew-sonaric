class SonaricRuntime < Formula
  desc "Sonaric Network Runtime"
  homepage "https://sonaric.xyz"
  version "0.0.1"

  depends_on "podman" => :recommended
  url "https://github.com/monk-io/homebrew-sonaric.git", branch: "main"

  def install
    bin.install "sonaric-runtime.sh" => "sonaric-runtime"
  end

  service do
    run [opt_bin/"sonaric-runtime"]
    keep_alive true
  end
end
