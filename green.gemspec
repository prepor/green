Gem::Specification.new do |s|
  s.specification_version = 2 if s.respond_to? :specification_version=
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.rubygems_version = '1.3.5'

  s.name              = 'green'
  s.version           = '0.0.1'
  s.date              = '2012-05-09'
  s.rubyforge_project = 'green'

  s.summary     = "Cooperative multitasking fo Ruby"
  s.description = "Cooperative multitasking fo Ruby"

  s.authors  = ["Andrew Rudenko"]
  s.email    = 'ceo@prepor.ru'
  s.homepage = 'http://github.com/prepor/green'

  s.require_paths = %w[lib]

  s.rdoc_options = ["--charset=UTF-8"]
  s.extra_rdoc_files = %w[README.md]

  s.add_runtime_dependency("kgio", "2.7.4")
  # = MANIFEST =
  s.files = %w[
    Gemfile
    Gemfile.lock
    Rakefile
    Readme.md
    app.ru
    green.gemspec
    lib/green-em/em-http.rb
    lib/green.rb
    lib/green/event.rb
    lib/green/ext.rb
    lib/green/group.rb
    lib/green/hub.rb
    lib/green/hub/em.rb
    lib/green/monkey.rb
    lib/green/semaphore.rb
    lib/green/tcp_socket.rb
  ]
  # = MANIFEST =

  ## Test files will be grabbed from the file list. Make sure the path glob
  ## matches what you actually use.
  s.test_files = s.files.select { |path| path =~ /^spec\/.*_spec\.rb/ }
end