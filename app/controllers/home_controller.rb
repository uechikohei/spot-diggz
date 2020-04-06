class HomeController < ApplicationController

  def index
      @api = StockQuote::Stock.new(api_key: 'pk_d9d2be72b48e42d2bbca152beb28d99a')

    begin
    if params[:ticker] == ""
      @nothing = "検索したい銘柄を入力してください。"
    elsif params[:ticker]
      @stock = StockQuote::Stock.quote(params[:ticker])
    end
    rescue RuntimeError => e
      @error = "該当する銘柄を見つけることはできませんでした。"
    end

  end

  def about
  end

end


# raiseは例外発生させる
## 使用するクラスはデフォルトで、RuntimeErrorクラス
# rescueメソッドで格納する変数は、execepetionクラス
## rescueメソッドで、格納する変数にRuntimeErrorクラスなど小クラスを指定しないとデバックなど行えなくなる。