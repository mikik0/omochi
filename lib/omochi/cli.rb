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
      exprs = get_public_method(diff_paths)
      exprs.each do |expr|
        dfs(expr[:ast], expr[:filename], def_name_hash)
      end
      p def_name_hash
      find_spec_files(def_name_hash)
      return true
    end

    desc "create local_path", "search all of new methods and functions but not spec created yet, after all create spec"
    def create()
    end
  end
end
