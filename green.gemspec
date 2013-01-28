Gem::Specification.new do |s|
  s.specification_version = 2 if s.respond_to? :specification_version=
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.rubygems_version = '1.3.5'

  s.name              = 'green'

  s.version           = '0.1.1'
  s.date              = '2013-01-28'

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
    README.md
    Rakefile
    app.ru
    green.gemspec
    lib/active_record/connection_adapters/green_mysql2_adapter.rb
    lib/green-em.rb
    lib/green-em/em-http.rb
    lib/green.rb
    lib/green/activerecord.rb
    lib/green/connection_pool.rb
    lib/green/event.rb
    lib/green/ext.rb
    lib/green/group.rb
    lib/green/hub.rb
    lib/green/hub/em.rb
    lib/green/hub/nio4r.rb
    lib/green/monkey.rb
    lib/green/mysql2.rb
    lib/green/semaphore.rb
    lib/green/socket.rb
    lib/green/zmq.rb
    spec/green/activerecord_spec.rb
    spec/green/connection_pool_spec.rb
    spec/green/event_spec.rb
    spec/green/group_spec.rb
    spec/green/monkey_spec.rb
    spec/green/mysql2_spec.rb
    spec/green/semaphore_spec.rb
    spec/green/socket_spec.rb
    spec/green/tcpsocket_spec.rb
    spec/green/zmq_spec.rb
    spec/green_spec.rb
    spec/helpers.rb
    spec/spec_helper.rb
  ]
  # = MANIFEST =

  ## Test files will be grabbed from the file list. Make sure the path glob
  ## matches what you actually use.
  s.test_files = s.files.select { |path| path =~ /^spec\/.*_spec\.rb/ }
end
