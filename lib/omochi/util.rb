# frozen_string_literal: true

require 'open3'
require 'parser/current'
require 'json'
require 'nokogiri'

module Omochi
  module Util
    include AST::Processor::Mixin

    def local_diff_path
      # Gitがインストールされているか確認
      unless system('git --version > /dev/null 2>&1')
        puts 'Error: Git is not installed. Please install Git.'
        return []
      end

      # ローカルのdiffを取得する
      diff_command = 'git diff --diff-filter=d --name-only'
      diff_output, _diff_error, _diff_status = Open3.capture3(diff_command, chdir: '.')

      # エラーチェック
      unless _diff_status.success?
        puts "Error: Failed to run 'git diff' command."
        return []
      end

      # 取得したdiffのpathを返却する
      diff_output.split("\n")
    end

    def github_diff_path
      diff_command = 'gh pr diff --name-only'
      diff_output, _diff_error, _diff_status = Open3.capture3(diff_command, chdir: '.')

      # エラーチェック
      unless _diff_status.success?
        puts "Error: Failed to run 'gh pr diff' command."
        return []
      end
      # 取得したdiffのpathを返却する
      diff_output.split("\n")
    end

    def remote_diff_path
      # リモートのdiffを取得する
      diff_command = 'git diff --name-only origin/${{ github.event.pull_request.base.ref }}..${{ github.sha }}'
      diff_output, _diff_error, _diff_status = Open3.capture3(diff_command, chdir: '.')

      # エラーチェック
      unless _diff_status.success?
        puts "Error: Failed to run 'git diff' command."
        return []
      end

      # 取得したdiffのpathを返却する
      diff_output.split("\n")
    end

    def get_ast(diff_path)
      exprs = []
      ast = Parser::CurrentRuby.parse(File.read(diff_path))
      exprs << { ast: ast, filename: diff_path }
    end

    def dfs(node, filename, result)
      return unless node.is_a?(Parser::AST::Node)

      # ノードの種類に応じて処理を実行
      case node.type
      when :def
        # :def ノードの場合、メソッド定義に関する処理を実行
        # ファイル名とメソッド名をつめてます。
        child_value = node.children[0]
        code = Unparser.unparse(node)
        result[child_value] = code
      end

      # 子ノードに対して再帰的に深さ優先探索
      node.children.each { |child| dfs(child, filename, result) }
    end

    def find_spec_file(diff_path)
      spec_path = File.join('spec', diff_path.gsub(/\.rb$/, '_spec.rb').gsub('app/', ''))
      File.exist?(spec_path) ? spec_path : nil
    end

    # rspecのdescribeでは、通常 # または . の直後に関数名を書くため
    def get_pure_function_name(str)
      if str.start_with?('#', '.')
        str[1..-1] # 2番目以降の文字列を返す
      else
        str # 変更が不要な場合はそのまま返す
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
      method_list = result.reject { |_key, value| value == true }.keys
      method_list.each do |file|
        puts "- \e[32m#{file}\e[0m"
      end

      method_list
    end

    def get_ignore_methods(diff_path)
      ignore_methods = []
      code = File.open(diff_path, 'r').read
      lines = code.split("\n")
      ignore_next_function = false

      lines.each do |line|
        if line.match(/omochi:ignore:*/) && line.strip.start_with?('#')
          ignore_next_function = true
          next
        end

        if ignore_next_function && line.match(/\s*def\s+(\w+)/)
          ignore_methods << Regexp.last_match(1)
          ignore_next_function = false
        end
      end

      ignore_methods
    end

    def process_spec_file(diff_path, create_spec, perfect)
      # 対応するSpecファイルが存在した場合のロジック
      result = {}
      spec_def_name_arr = []
      spec_file_path = find_spec_file(diff_path)
      # スペックファイルがあれば、specfileの中身を確認していく。
      # defメソッド名だけ切り出す {:call => {code}, :verify => {code}, ....}
      # ASTを再帰的に探索し、メソッド名とコードを取得
      get_ast(diff_path).each do |expr|
        dfs(expr[:ast], expr[:filename], result)
      end
      result = result.transform_keys(&:to_s)
      # describeメソッド [call]
      # []の中にastが入る
      get_ast(spec_file_path).each do |expr|
        spec_def_name_arr = dfs_describe(expr[:ast], expr[:filename], spec_def_name_arr)
      end

      # resultのHashでSpecが存在するものをTrueに更新
      spec_def_name_arr.each do |spec_def_name|
        next unless result.key?(spec_def_name)

        result[spec_def_name] = true

        next unless create_spec

        method_code = result[spec_def_name]
        puts '==================================================================='
        puts "#{spec_def_name} のテストを以下に表示します。"
        create_spec_by_bedrock(method_code)
      end

      get_ignore_methods(diff_path).each do |def_name|
        result[def_name] = true if result.key?(def_name)
      end

      perfect = false if print_result(diff_path, result).size > 0

      perfect
    end

    def process_missing_spec_file(diff_path, create_spec, perfect)
      # 対応するSpecファイルが存在しない場合のロジック
      result = {}
      spec_def_name_arr = []
      spec_file_path = find_spec_file(diff_path)
      ignored_def_names = get_ignore_methods(diff_path)
      get_ast(diff_path).each do |expr|
        dfs(expr[:ast], expr[:filename], result)
      end
      result = result.transform_keys(&:to_s)

      ignored_def_names.each do |def_name|
        result[def_name] = true if result.key?(def_name)
      end

      perfect = false if print_result(diff_path, result).size > 0

      return unless create_spec

      # exprs[0] の AST からメソッド内のコードを生成
      ast_code = get_ast(diff_path)[0][:ast]
      method_code = Unparser.unparse(ast_code)

      puts '==================================================================='
      puts "#{diff_path} のテストを以下に表示します。"
      create_spec_by_bedrock(method_code)
    end

    def create_spec_by_bedrock(code)
      # 必要な関数だけ渡すのと比較する。
      bedrock_client = Aws::BedrockRuntime::Client.new(region: 'us-east-1')
      comment = "You are a brilliant Ruby programmer.
You have been assigned to a project to automate QA testing for a system.
Please write the Ruby function you want to test inside the <code> XML tags.
Write the tests using RSpec to cover all branches of the function comprehensively.
Include many test cases to thoroughly verify the function.
You must output the test code inside the <test> XML tags absolutely.
Do not include any content besides the test code. <code> #{code} </code>"
      body_data = {
        "anthropic_version": 'bedrock-2023-05-31',
        "max_tokens": 4000,
        "temperature": 0.0,
        "messages": [
          {
            "role": 'user',
            "content": "#{comment}"
          }
        ]
      }
      response = bedrock_client.invoke_model({
        accept: '*/*',
        content_type: 'application/json',
        body: body_data.to_json,
        model_id: 'anthropic.claude-3-sonnet-20240229-v1:0'
      })

      string_io_object = response.body
      data = JSON.parse(string_io_object.string)
      code_html = data['content'][0]['text']

      # nokogiri を使用して HTML を解析し、<test> タグの中身を取得
      doc = Nokogiri::HTML(code_html)
      code_content = doc.at('test').content.strip

      puts code_content
    end
  end
end
