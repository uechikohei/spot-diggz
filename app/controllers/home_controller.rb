class HomeController < ApplicationController

  def index
    @maps = Map.all
      # ransack
    @key = Map.ransack(params[:q])
    @results = @key.result(distinct: true)
  end

end