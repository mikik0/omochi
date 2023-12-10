# frozen_string_literal: true
require 'open3'
require 'parser/current'

include AST::Processor::Mixin

def local_diff_path(repository_path)
  # Gitがインストールされているか確認
  unless system('git --version > /dev/null 2>&1')
    puts "Error: Git is not installed. Please install Git."
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
end

def get_public_method(diff_paths)
  exprs = []
  diff_paths.each do |diff_path|
    if File.extname(diff_path) != ".rb"
      next
    end
    # exprs << Parser::CurrentRuby.parse(File.read(diff_path))
    # exprs.merge!(:ast => Parser::CurrentRuby.parse(File.read(diff_path)), :filename => diff_path)
    # exprs[:filename] = diff_path
    exprs << {:ast => Parser::CurrentRuby.parse(File.read(diff_path)), :filename => diff_path }
  end
  exprs
end

def dfs(expr, def_name_hash)
  #astを取り出せば動くぜ？
  # p "-----------------1----------------------------"
  # p expr[:ast]
  # p "-----------------2----------------------------"
  # # p def_name_hash
  node = expr.first
  return unless node.is_a?(Parser::AST::Node)

  # ノードの種類に応じて処理を実行
  case node.type
  when :def
    # p ""
    # p "-----------------def----------------------------"

    # :def ノードの場合、メソッド定義に関する処理を実行
    process_def_node(node, def_name_hash)
  end

  # 子ノードに対して再帰的に深さ優先探索
  node.children.each { |child| dfs(child, def_name_hash) }
end

def process_def_node(node, def_name_hash)
  # :def ノードに対する処理を記述
  # puts "Processing def node: #{node}"
  p "-----------------def----------------------------"
  # p node.children[0]
  def_name_hash = {}
  def_name_hash[node.children[0]]
  # ここでファイル名と関数名をhashにつめる！
  def_name_hash << { :diff_path => def_name_hash[node.children[0]] }
  p def_name_hash
end
