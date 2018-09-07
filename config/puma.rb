#!/usr/bin/env puma

directory '/var/www/cityspade/current'
environment 'production'
daemonize true
pidfile "/var/www/cityspade/shared/tmp/pids/puma.pid"
state_path "/var/www/cityspade/shared/tmp/pids/puma.state"
stdout_redirect '/var/www/cityspade/shared/log/puma_error.log', '/var/www/cityspade/shared/log/puma_access.log', true
threads 4,16
bind "unix:///tmp/sockets/cityspade.puma.sock"

workers 4
preload_app!

on_restart do
  puts 'On restart...Refresh ENV["BUNDLE_GEMFILE"]'
  ENV["BUNDLE_GEMFILE"] = "/var/www/cityspade/current/Gemfile"
end

on_worker_boot do
  ActiveSupport.on_load(:active_record) do
    ActiveRecord::Base.establish_connection
  end
end

