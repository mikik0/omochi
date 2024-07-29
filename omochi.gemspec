# frozen_string_literal: true

require_relative 'lib/omochi/version'

Gem::Specification.new do |spec|
  spec.name = 'omochi'
  spec.version = Omochi::VERSION
  spec.authors = ['mikiko.hashino']
  spec.email = ['mikko.1222.u@gmail.com']

  spec.summary = 'Omochi is a CLI tool to support Ruby on Rails development with RSpec.'
  spec.description = 'Omochi is a CLI tool to support Ruby on Rails development with RSpec.'
  spec.homepage = 'https://github.com/mikik0/omochi'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 2.6.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/mikik0/omochi'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) || f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor])
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'aws-sdk-bedrockruntime'
  spec.add_dependency 'dotenv'
  spec.add_dependency 'nokogiri'
  spec.add_dependency 'parser'
  spec.add_dependency 'rspec'
  spec.add_dependency 'thor'
  spec.add_dependency 'unparser'
end
