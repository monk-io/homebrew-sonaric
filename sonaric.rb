class Sonaric < Formula
  desc "Sonaric Network: the AI-powered backbone for all blockchains."
  homepage "https://sonaric.xyz"
  version "0.0.11"

  url_x64 = "https://storage.googleapis.com/sonaric-releases/stable/macos/sonaric-darwin-v0.0.11.tar.gz"
  sha256_x64 = "1a586d718104fb2db34d237f8303586c569e4ccb617647dfe2d82c769ec31791"
  url_arm64 = "https://storage.googleapis.com/sonaric-releases/stable/macos/sonaric-arm-darwin-v0.0.11.tar.gz"
  sha256_arm64 = "d5b4c5fb61e9848453866a4404a162956ebb4421d3ce9ffd79cabe420eb9e574"

  if Hardware::CPU.intel?
    sha256 sha256_x64
    url url_x64
  else
    sha256 sha256_arm64
    url url_arm64
  end

  depends_on "podman" => :recommended

  def install
    bin.install "sonaric" => "sonaric"
    bin.install "sonaricd" => "sonaricd"
  end

  def caveats; <<~EOS
    Initialize the sonaric machine with sonaric daemon inside
      sonaric machine init

    Upgrade sonaric daemon inside the sonaric machine to the latest version
      sonaric machine upgrade
    EOS
  end
end
