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

def get_public_method(diff_paths)
  exprs = []
  diff_paths.each do |diff_path|
    if File.extname(diff_path) != ".rb"
      next
    end

    exprs << {:ast => Parser::CurrentRuby.parse(File.read(diff_path)), :filename => diff_path }
  end
  exprs
end

def dfs(node, filename, def_name_hash)
  return unless node.is_a?(Parser::AST::Node)

  # ノードの種類に応じて処理を実行
  case node.type
  when :def
    # :def ノードの場合、メソッド定義に関する処理を実行
    # ファイル名とメソッド名をつめてます。
    def_name_hash << { :diff_path => filename, :def_name => node.children[0] }
  end

  # 子ノードに対して再帰的に深さ優先探索
  node.children.each { |child| dfs(child, filename, def_name_hash) }
end

def find_spec_files(methods_data)
  spec_files = []

  methods_data.each do |data|
    diff_path = data[:diff_path]
    def_name = data[:def_name]

    # 対応するspecファイルのパスを構築
    spec_path = File.join('spec', diff_path.sub(/\.rb$/, '_spec.rb'))

    # specファイルが存在するか確認
    if File.exist?(spec_path)
      spec_files << spec_path
    else
      puts "Spec file not found for method '#{def_name}' in '#{diff_path}'."
    end
  end

  spec_files
end
