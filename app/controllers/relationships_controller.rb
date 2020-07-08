class RelationshipsController < ApplicationController
  before_action :set_user

  def follow
    current_user.follow(params[:id])
    respond_to do |format|
      format.html { redirect_back(fallback_location: root_path) }
      format.js
    end
  end

  def unfollow
    current_user.unfollow(params[:id])
    respond_to do |format|
      format.html { redirect_back(fallback_location: root_path) }
      format.js
    end
  end

  private
    def set_user
      @user = User.find(params[:id])
    end

end
