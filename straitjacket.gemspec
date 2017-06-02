app_root = File.expand_path('..', __FILE__)
files    = File.join('lib', '**', '*.rb')

$: << File.join(app_root, 'lib')
require 'sj/version'

Gem::Specification.new do |s|
  s.name        = 'sj'
  s.version     = SJ::VERSION
  s.date        = '2017-06-01'
  s.summary     = 'Straitjacket'
  s.description = 'Write maintainable, composable software.'
  s.authors     = ['Joshua Morris']
  s.email       = 'joshua@dailykos.com'
  s.executables = []
  s.files       = Dir.glob(files)
  s.homepage    = 'https://github.com/dailykos/straitjacket'
  s.license     = 'MIT'

  s.add_development_dependency 'rspec', '~> 3.6'
end

