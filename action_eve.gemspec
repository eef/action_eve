$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "action_eve/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "action_eve"
  s.version     = Actioneve::VERSION
  s.authors     = ["Arthur Canal"]
  s.email       = ["uberhaqer@gmail.com"]
  s.homepage    = "https://actioneve.evecom.io"
  s.summary     = "EVE API Lib"
  s.description = "EVE API Lib"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 4.1.8"

  s.add_development_dependency "sqlite3"
end
