# Rubyのバージョンを指定
FROM ruby:latest

# 作業ディレクトリを設定
WORKDIR /omochi
COPY . .

CMD ["while true; do sleep 1; done"]
