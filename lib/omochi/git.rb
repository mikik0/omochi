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

def find_spec_files(methods_data, no_spec_files)
  spec_files = []

  methods_data.each do |data|
    diff_path = data[:diff_path]
    def_name = data[:def_name]

    # 対応するspecファイルのパスを構築
    spec_path = File.join('spec', diff_path.sub(/\.rb$/, '_spec.rb'))

    # specファイルが存在するか確認
    if File.exist?(spec_path)
      # メソッドのテストが存在するか確認
      # test_exists = test_exists_for_method?(spec_path, def_name)
      get_spec_method(spec_path)
      # spec_files << spec_path
    else
      no_spec_files << { :diff_path => diff_path, :def_name => def_name }
    end
  end

  spec_files
end

def get_spec_method(diff_spec_path)
  exprs = []
    # if File.extname(diff_path) != ".rb"
    #   next
    # end

    exprs << {:ast => Parser::CurrentRuby.parse(File.read(diff_spec_path)), :filename => diff_spec_path }
  p "成功!!!!!!!!!"
  p exprs

end

def dfs_describe(node, filename, def_name_hash)
  return unless node.is_a?(Parser::AST::Node)

  # ノードの種類に応じて処理を実行
  case node.type
  when :describe
    # :describe ノードの場合、メソッド定義に関する処理を実行
    # ファイル名とメソッド名をつめてます。
    def_name_hash << { :diff_path => filename, :def_name => node.children[0] }
  end

  # 子ノードに対して再帰的に深さ優先探索
  node.children.each { |child| dfs(child, filename, def_name_hash) }

end

def extract_describe_values(ast)
  describe_values = []

  # 深さ優先探索
  ast.each do |node|
    if node.is_a?(Symbol) && node == :describe
      # :describeノードを見つけたらその後の要素を取得
      describe_values << get_next_str_value(ast)
    elsif node.is_a?(Array)
      # 配列の中も探索
      describe_values.concat(extract_describe_values(node))
    end
  end

  describe_values #Omochi::CLI verify 改行で表示される。
end

def get_next_str_value(ast)
  str_value = nil

  # :describeの後ろにある:strの値を取得
  ast.each_cons(2) do |node, next_node|
    if node.is_a?(Symbol) && node == :describe && next_node.is_a?(Array) && next_node[0] == :str
      str_value = next_node[1]
      break
    end
  end

  str_value
end


# def dfs_search(path)
#   if File.directory?(path)
#     Dir.entries(path).each do |entry|
#       next if entry == '.' || entry == '..'
#       dfs_search(File.join(path, entry))
#     end
#   elsif File.file?(path) && File.extname(path) == '.rb'
#     puts path
#   end
# end

# def test_exists_for_method?(spec_path, def_name)
#   describe_block_opened = false
#   test_found = false

#   File.foreach(spec_path) do |line|
#     describe_block_opened ||= line =~ /^\s*describe\s+[^\s]+(\s+do)?\s*$/

#     if describe_block_opened && line =~ /^\s*it\s+'#{def_name}'\s+do\s*$/
#       test_found = true
#       break
#     end

#     describe_block_opened = false if line =~ /^\s*end\s*$/
#   end

#   test_found
# end
