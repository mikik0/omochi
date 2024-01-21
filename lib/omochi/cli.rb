# frozen_string_literal: true
require "omochi"
require 'thor'
require "omochi/git"

module Omochi
  # class Error < StandardError; end
  class CLI < Thor
    desc "red WORD", " words print." # コマンドの使用例と、概要
    def red(word) # コマンドはメソッドとして定義する
      say(word, :red)
    end

    desc "verify local_path", "verify spec created for all of new methods and functions"
    method_option :github, aliases: "-h", desc: "Running on GitHub Action"
    def verify()
      is_gh_action = options[:github]
      is_gl_ci_runner = false
      perfect = true
      result = {}
      def_name_arr = []

      case [is_gh_action, is_gl_ci_runner]
      when [true, false]
        diff_paths = github_diff_path
      when [false, true]
        diff_paths = remote_diff_path
      when [false, false]
        diff_paths = local_diff_path
      end

      p "Verify File List: #{diff_paths}"
      # diff_paths 例: ["lib/omochi/cli.rb", "lib/omochi/git.rb", "spec/lib/omochi/cli_spec.rb"]
      diff_paths.each do |diff_path|
        spec_file_path = find_spec_file(diff_path)
        if !spec_file_path.nil?
          p "specファイルあり"
          # ここから対応するSpecファイルが存在した場合のロジック
          # スペックファイルがあれば、specfileの中身を確認していく。
          # defメソッド名だけ切り出す {:call => false, :verify => false, ....}
          exprs = get_public_method(diff_path) #wip メソッド名ast
          exprs.each do |expr|
            dfs(expr[:ast], expr[:filename], result)
          end
          result = result.transform_keys(&:to_s)
          # describeメソッド [call]
          exprs = get_public_method(spec_file_path) # []の中にastが入る
          exprs.each do |expr|
            def_name_arr = dfs_describe(expr[:ast], expr[:filename], def_name_arr)
          end
          # resultのHashでSpecが存在するものをTrueに更新
          def_name_arr.each do |def_name|
            if result.key?(def_name)
              result[def_name] = true
            end
          end

          if print_result(diff_path, result).size > 0
            perfect = false
          end
        else
          # ここから対応するSpecファイルが存在しない場合のロジック
          p "specファイルなし"
          exprs = get_public_method(diff_path)
          exprs.each do |expr|
            dfs(expr[:ast], expr[:filename], result)
          end
          result = result.transform_keys(&:to_s)
          if print_result(diff_path, result).size > 0
            perfect = false
          end
        end
      end

      # perfect じゃない場合は、異常終了する
      exit(perfect ? 0 : 1)

      # exprs = get_public_method(diff_paths)
      # exprs.each do |expr|
      #   dfs(expr[:ast], expr[:filename], def_name_hash)
      # end
      # no_spec_files = []
      # diff_paths = find_spec_files(def_name_hash, no_spec_files) # テストがあるspecファイル / テストがないのはハッシュ(ファイル名とメソッド名)に保存しておく。
      # # diff_paths 例: ["spec/lib/omochi/cli_spec.rb", "spec/lib/omochi/cli_spec.rb", "spec/lib/omochi/cli_spec.rb"]
      # exprs = get_spec_method(diff_paths) # []の中にastが入る
      # exprs.each do |expr|
      #   dfs_describe(expr[:ast], expr[:filename], def_name_hash_2)
      # end

      # 深さ優先探索を行う
      # そのファイルをastにして、describeを探す. describe_values
      # テストの見つからなかった関数(関数名+ファイル名)のリストをreturn
      # lenが0だったらsuccess、1異常ならfailでverifyは終わり
    end

    desc "create local_path", "search all of new methods and functions but not spec created yet, after all create spec"
    def create()
    end
  end
end
