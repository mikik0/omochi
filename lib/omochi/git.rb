# frozen_string_literal: true

require 'open3'

module Omochi
  class Git
    def local_diff_path(repository_path)
      # Gitがインストールされているか確認
      unless system('git --version > /dev/null 2>&1')
        puts "Error: Git is not installed. Please install Git."
        return []
      end

      # 指定されたディレクトリがGitリポジトリであるか確認
      unless Dir.exist?(File.join(repository_path, '.git'))
        puts "Error: The specified directory is not a Git repository."
        return []
      end

      # ローカルのdiffを取得する
      diff_command = "git diff --name-only"
      diff_output, _diff_error, _diff_status = Open3.capture3(diff_command, chdir: repository_path)

      # エラーチェック
      unless _diff_status.success?
        puts "Error: Failed to run 'git diff' command."
        return []
      end

      # 取得したdiffのpathを返却する
      diff_paths = diff_output.split("\n")
      diff_paths
    end
  end
end
