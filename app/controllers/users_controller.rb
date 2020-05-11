class UsersController < ApplicationController
  before_action :authenticate_user!, only: %i[show index]

  def index
    @users = User.page(params[:page]).per(2)
  end

  def show
    @user = User.find_by(id: params[:id])
  end
end
