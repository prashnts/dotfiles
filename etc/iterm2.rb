class Iterm2 < Formula
  version "master"
  desc "Patched iTerm2 with configurable borders"
  homepage "https://www.iterm2.com/"
  url "https://github.com/gnachman/iTerm2.git"

  option "with-padding", "Skip removing padding."

  depends_on :xcode
  depends_on :arch => :x86_64

  def install
    if not build.with? "padding"
      ohai "Patching Margins"
      inreplace "sources/iTermTextDrawingHelper.h" do |s|
        s.gsub! "#define MARGIN 5", "#define MARGIN 0"
        s.gsub! "#define VMARGIN 2", "#define VMARGIN 0"
      end
    end
    system "make", "prod"
    prefix.install "build/Deployment/iTerm2.app"
  end

  test do
    system "ci/script.sh"
  end
end
