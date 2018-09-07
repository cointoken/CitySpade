set :application, 'CitySpade'
# github
set :repo_url, 'git@github.com:alexhsfz/CitySpade'
# bitbacket
# set :repo_url, 'git@bitbucket.org:cityspade/cityspade'

# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }

# set :deploy_to, '/var/www/my_app'
set :scm, :git

set :format, :pretty
set :log_level, :debug
set :pty, true
set :ssh_options, { :forward_agent => true }


set :deploy_via, :remote_cache
set :git_shallow_clone, 1
set :git_enable_submodules, 1

set :rvm1_ruby_version, "2.1.3"

# fix gemfile default to current dir
set :bundle_gemfile, -> { release_path.join('Gemfile') }

set :linked_files, %w{config/database.yml config/settings.yml}
# config/puma.rb
set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

# set :default_env, { path: "/opt/ruby/bin:$PATH" }
set :keep_releases, 10
set :default_shell, '/bin/bash -l'

namespace :sitemaps do
  task :create_symlink do
    on roles(:app), in: :sequence do
      execute "mkdir -p #{shared_path}/sitemaps"
      execute "rm -rf #{release_path}/public/sitemaps"
      execute "ln -s #{shared_path}/sitemaps #{release_path}/public/sitemaps"
    end
  end
end
namespace :deploy do

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      # execute 'sudo service mysqld restart'
      # Your restart mechanism here, for example:
      # execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  task :upload_config_file do
    on roles(:app), in: :sequence, wait: 5 do
      Dir['config/settings.yml'].each do |file|
        target_dir = shared_path
        target_dir = File.join(target_dir, 'config') unless file.include?('puma.rb')
        upload!(File.expand_path(file),  "#{target_dir}/#{File.basename(file)}")
      end
    end
  end

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end

  task :setup do
    on roles(:app) do

    end
  end

  task :write_crontab do
    on roles(:crontab), in: :sequence do
      within current_path do
        execute :bundle, 'exec', 'whenever -w'
      end
    end
  end

  task :sitemaps do
    on roles(:app) do
      within current_path do
        execute :bundle, 'exec', 'rake "sitemap:generate"', 'RAILS_ENV=production'
      end
    end
  end

  after :finishing, 'deploy:cleanup'
  after :finishing, 'deploy:sitemaps'
  after :finishing, 'deploy:write_crontab'
  after :restart, 'puma:smart_restart'
  after :finishing, "sitemaps:create_symlink"
end

#namespace :solr do
  #desc "start solr"
  #task :start do
    #on roles(:app),in: :sequence do
      #within current_path do
        #unless  test "[ -f #{shared_path}/solr/data ]"
          #execute :mkdir, "-p #{shared_path}/solr/data"
        #end
        #execute :bundle,  'exec',  'sunspot-solr',  "start --port=8983 --data-directory=#{shared_path}/solr/data --pid-dir=#{shared_path}/tmp/pids"
      #end
    #end
  #end
  #desc "stop solr"
  #task :stop do
    #on roles(:app),in: :sequence do
      #within current_path do
        #execute :bundle,  'exec',  'sunspot-solr',  "stop --port=8983 --data-directory=#{shared_path}/solr/data --pid-dir=#{shared_path}/tmp/pids"
      #end
    #end
  #end
  #desc "reindex the whole database"
  #task :reindex  do
    #on roles(:app),in: :sequence do
      #within current_path do
        #invoke 'solr:stop'
        #execute :rm, "-rf #{shared_path}/solr/data"
        #invoke 'solr:start'
        #execute :rake, 'sunspot:solr:reindex'
      #end
    #end
  #end
#end
