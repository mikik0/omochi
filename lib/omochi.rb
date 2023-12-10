# frozen_string_literal: true

require_relative "omochi/version"
require "omochi/cli"

module Omochi
  # class Error < StandardError; end
  class CLI < Thor
    desc "red WORD", "red words print." # コマンドの使用例と、概要
    def red(word) # コマンドはメソッドとして定義する
      say(word, :red)
    end
  end
end
