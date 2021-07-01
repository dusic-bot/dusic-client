# frozen_string_literal: true

namespace :dusic do
  desc 'Build all binaries'
  task :build do
    on roles(:app) do
      within release_path do
        execute :make, :all
      end
    end
  end

  desc 'Get service status via systemd'
  task :status do
    on roles(:app) do
      execute '/bin/systemctl status dusic-cluster'
    end
  end

  desc 'Start service via systemd (requires sudo with no password)'
  task :start do
    on roles(:app) do
      execute 'sudo /bin/systemctl start dusic-cluster'
    end
  end

  desc 'Stop service via systemd (requires sudo with no password)'
  task :stop do
    on roles(:app) do
      execute 'sudo /bin/systemctl stop dusic-cluster'
    end
  end

  desc 'Restart service status via systemd (requires sudo with no password)'
  task :restart do
    on roles(:app) do
      execute 'sudo /bin/systemctl restart dusic-cluster'
    end
  end
end

after 'deploy:published', 'dusic:build'
