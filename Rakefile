# frozen_string_literal: true

require 'bundler'

Bundler::GemHelper.install_tasks

# The publish workflow sets FARADAY_RELEASE because its bundle (release/Gemfile) doesn't include RSpec.
unless ENV['FARADAY_RELEASE']
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new(:spec) do |task|
    task.ruby_opts = %w[-W]
    # Integration specs need service containers, see .github/workflows/integration-tests.yml
    task.exclude_pattern = 'spec/integration/**/*_spec.rb'
  end

  task default: :spec

  namespace :bench do
    desc 'Fail if a hot path allocates more objects than bench/allocations.yml says'
    task :allocations do
      ruby '-Ilib bench/allocations.rb'
    end

    namespace :allocations do
      desc 'Write the allocation counts of this checkout to bench/allocations.yml'
      task :update do
        ruby '-Ilib bench/allocations.rb --update'
      end
    end

    desc 'Compare the speed of this checkout with a git ref (default: origin/main)'
    task :compare, [:ref] do |_task, args|
      ref = args[:ref] || 'origin/main'
      base = File.join('tmp', 'bench', ref.tr('/', '-'))
      rm_rf base
      mkdir_p base
      sh "git archive #{ref} lib | tar -x -C #{base}"
      ruby "bench/compare.rb #{base}/lib lib"
    end
  end
end
