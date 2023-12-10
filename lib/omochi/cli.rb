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
    def verify(path)
      @def_name_hash = {}
      diff_paths = local_diff_path(path)
      exprs = get_public_method(diff_paths)
      p exprs
      exprs.each do |expr|
        p expr
      end
    end

    desc "create local_path", "search all of new methods and functions but not spec created yet, after all create spec"
    def create()
    end
  end
end
