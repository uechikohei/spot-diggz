class UsersController < ApplicationController
  before_action :authenticate_user!, only: %i[show index]

  def index
    @users = User.all
  end

  def show
    @user = User.find_by(id: params[:id])
  end
end
