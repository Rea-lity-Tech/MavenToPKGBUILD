
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "MavenToPKGBUILD/version"

Gem::Specification.new do |spec|
  spec.name          = "MavenToPKGBUILD"
  spec.version       = MavenToPKGBUILD::VERSION
  spec.authors       = ["Jeremy Laviole"]
  spec.email         = ["laviole@rea.lity.tech"]

  spec.summary       = %q{Create packages for Arch linux (AUR) for Maven dependencies.}
  spec.description   = %q{The packages are installed in /usr/share/java, as it is recommended in the PKGBUILD for java guide. For now and in the future I try to stick to the official guidelines.

This is a first implementation to manage dependencies for java programs that share jar files. The goal is to distribute java programs and its dependencies separated in a clean way. However the current risk is that we have to create dozens or hundreds of packages for large projects.}
  
  spec.homepage      = "https://github.com/Rea-lity-Tech/MavenToPKGBUILD"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "http://mygemserver.com"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
end
