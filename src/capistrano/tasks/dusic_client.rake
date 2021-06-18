# frozen_string_literal: true

namespace 'dusic_client' do
  task 'build' do
    on roles(:app) do
      within release_path do
        execute :make, :all
      end
    end
  end

  task 'start' do
    # TODO
  end
end

after 'deploy:published', 'dusic_client:build'
