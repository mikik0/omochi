# frozen_string_literal: true

require 'omochi'
require 'thor'
require 'omochi/util'
require 'yaml'
require 'aws-sdk-bedrockruntime'
require 'dotenv/load'
require 'unparser'

module Omochi
  class CLI < Thor
    class << self
      def exit_on_failure?
        true
      end
    end

    desc 'verify local_path', 'verify spec created for all of new methods and functions'
    method_option :github, aliases: '-h', desc: 'Running on GitHub Action'
    method_option :create, aliases: '-c', desc: 'Create Spec for Untested Method'
    def verify
      is_gh_action = options[:github] == 'github'
      is_gl_ci_runner = false
      create_spec = options[:create] == 'create'
      perfect = true

      diff_paths = case [is_gh_action, is_gl_ci_runner]
                    when [true, false]
                      github_diff_path
                    when [false, true]
                      remote_diff_path
                    when [false, false]
                      local_diff_path
                    end

      # Ruby 以外のファイル(yamlやmdなど)を除外 specファイルも除外(テストにはテストない)
      diff_paths.reject! { |s| !s.end_with?('.rb') || s.end_with?('_spec.rb') }
      p "Verify File List: #{diff_paths}"

      # diff_paths 例: ["lib/omochi/cli.rb", "lib/omochi/util.rb"]
      diff_paths.each do |diff_path|
        if find_spec_file(diff_path)
          p 'specファイルあり'
          process_spec_file(diff_path, create_spec, perfect)
        else
          p 'specファイルなし'
          process_missing_spec_file(diff_path, create_spec, perfect)
        end
      end
        exit(perfect ? 0 : 1)
      end
    end
  end
