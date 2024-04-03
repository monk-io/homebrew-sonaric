class Sonaric < Formula
  desc "Sonaric Network: the AI-powered backbone for all blockchains."
  homepage "https://sonaric.xyz"
  version "0.0.6"

  url_x64 = "https://storage.googleapis.com/sonaric-releases/stable/macos/sonaric-darwin-v0.0.6.tar.gz"
  sha256_x64 = "63ab623c49db4bd563ce0b1bc84cfb0b52b7e8937ad69e1f933ddaa7cb097f89"
  url_arm64 = "https://storage.googleapis.com/sonaric-releases/stable/macos/sonaric-arm-darwin-v0.0.6.tar.gz"
  sha256_arm64 = "caaefbe6ea2da8bc53859e62b95837071633d51497a04b68ab0ffa2ff69a9313"

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
