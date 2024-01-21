# frozen_string_literal: true
require 'open3'
require 'parser/current'

include AST::Processor::Mixin

def local_diff_path()
  # Gitがインストールされているか確認
  unless system('git --version > /dev/null 2>&1')
    puts "Error: Git is not installed. Please install Git."
    return []
  end

  # ローカルのdiffを取得する
  diff_command = "git diff --name-only"
  diff_output, _diff_error, _diff_status = Open3.capture3(diff_command, chdir: ".")

  # エラーチェック
  unless _diff_status.success?
    puts "Error: Failed to run 'git diff' command."
    return []
  end

  # 取得したdiffのpathを返却する
  diff_paths = diff_output.split("\n")
end

def github_diff_path()
  diff_command = "gh pr diff --name-only"
  diff_output, _diff_error, _diff_status = Open3.capture3(diff_command, chdir: ".")

   # エラーチェック
   unless _diff_status.success?
    puts "Error: Failed to run 'gh pr diff' command."
    return []
  end
  # 取得したdiffのpathを返却する
  diff_paths = diff_output.split("\n")
end

def remote_diff_path()
  # リモートのdiffを取得する
  diff_command = "git diff --name-only origin/${{ github.event.pull_request.base.ref }}..${{ github.sha }}"
  diff_output, _diff_error, _diff_status = Open3.capture3(diff_command, chdir: ".")

  # エラーチェック
  unless _diff_status.success?
    puts "Error: Failed to run 'git diff' command."
    return []
  end

  # 取得したdiffのpathを返却する
  diff_paths = diff_output.split("\n")
end

def get_public_method(diff_path)
  exprs = []
  exprs << {:ast => Parser::CurrentRuby.parse(File.read(diff_path)), :filename => diff_path }
end

def dfs(node, filename, result)
  return unless node.is_a?(Parser::AST::Node)

  # ノードの種類に応じて処理を実行
  case node.type
  when :private
    return
  when :def
    # :def ノードの場合、メソッド定義に関する処理を実行
    # ファイル名とメソッド名をつめてます。
    child_value = node.children[0]
    result[child_value] = false
  end

  # 子ノードに対して再帰的に深さ優先探索
  node.children.each { |child| dfs(child, filename, result) }
end

def find_spec_file(diff_path)
  spec_path = File.join('spec', diff_path.gsub(/\.rb$/, '_spec.rb').gsub('app/', ''))
  p spec_path
  return File.exist?(spec_path) ? spec_path : nil
end

# rspecのdescribeでは、通常 # または . の直後に関数名を書くため
def get_pure_function_name(str)
  if str.start_with?("#", ".")
    str[1..-1]  # 2番目以降の文字列を返す
  else
    str        # 変更が不要な場合はそのまま返す
  end
end

def dfs_describe(node, filename, def_name_arr)
  return unless node.is_a?(Parser::AST::Node)

  # ノードの種類に応じて処理を実行
  case node.type
  when :send
    method_node = node.children[1]
    if node.children[1] == :describe
      def_name = node.children[2].children[0] # "Omochi::CLI"
      if !def_name.nil? && def_name.is_a?(String)
        def_name = get_pure_function_name(def_name)
        def_name_arr.push(def_name)
      end
    end
  end

  # 子ノードに対して再帰的に深さ優先探索
  node.children.each { |child| dfs_describe(child, filename, def_name_arr) }
   def_name_arr
end

def print_result(filename, result)
  puts "\e[31m======= RESULT: #{filename} =======\e[0m"
  method_list = result.select { |key, value| value == false }.keys
  method_list.each do |file|
    puts "- \e[32m#{file}\e[0m"
  end

  method_list
end
