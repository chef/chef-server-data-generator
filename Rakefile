task :install_deps do
  # configure bundler to pass our pg config to knife-ec-backup
  `/opt/opscode/embedded/bin/bundle config build.knife-ec-backup --with-pg-config=/opt/opscode/embedded/postgresql/9.2/bin/pg_config`
  if RUBY_VERSION[0] == "2" # install from git master for Ruby 2, mostly like needed for post-migration
    `BUNDLE_GEMFILE=./Gemfile_ruby_2 /opt/opscode/embedded/bin/bundle install`
  else # install version of knife-ec-backup supported by Ruby 1 (most likely needed for EC/OCS11)
    `BUNDLE_GEMFILE=./Gemfile_ruby_1 /opt/opscode/embedded/bin/bundle install`
  end
end
