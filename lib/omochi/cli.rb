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
    def verify()
      def_name_hash = []
      diff_paths = local_diff_path()
      # diff_paths 例: ["lib/omochi/cli.rb", "lib/omochi/git.rb", "spec/lib/omochi/cli_spec.rb"]
      exprs = get_public_method(diff_paths)
      exprs.each do |expr|
        dfs(expr[:ast], expr[:filename], def_name_hash)
      end
      no_spec_files = []
      find_spec_files(def_name_hash, no_spec_files) # テストがあるspecファイル / テストがないのはハッシュ(ファイル名とメソッド名)に保存しておく。
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
