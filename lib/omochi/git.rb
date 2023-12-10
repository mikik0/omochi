# frozen_string_literal: true
require 'open3'

def local_diff_path(repository_path)
  # Gitがインストールされているか確認
  unless system('git --version > /dev/null 2>&1')
    puts "Error: Git is not installed. Please install Git."
    return []
  end

  # ローカルのdiffを取得する
  diff_command = "git diff --name-only"
  diff_output, _diff_error, _diff_status = Open3.capture3(diff_command, chdir: repository_path)
  puts diff_output
  puts "ーーーーーーーーーーーーーーーーーーーーーー"
  puts _diff_error
  puts "ーーーーーーーーーーーーーーーーーーーーーー"
  puts _diff_status


  # エラーチェック
  unless _diff_status.success?
    puts "Error: Failed to run 'git diff' command."
    return []
  end

  # 取得したdiffのpathを返却する
  diff_paths = diff_output.split("\n")
  diff_paths
end
