class UsersController < ApplicationController
  before_action :authenticate_user!, only: %i[destroy edit]

  def index
    @users = User.all
  end

  def show
    @user = User.find_by(id: params[:id])
    @map = Map.find_by(id: params[:id])
  end

  def edit
  end

  def destroy
    @map.destroy
    respond_to do |format|
      format.html { redirect_to maps_url, notice: 'アカウントが無事削除されました！' }
    end
  end

end
