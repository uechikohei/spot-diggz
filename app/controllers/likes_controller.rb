class LikesController < ApplicationController
  before_action :set_post

  def create
    @like = current_user.likes.create(map_id: params[:map_id])
    @like.save
    respond_to do |format|
      format.html { redirect_back(fallback_location: root_path) }
      format.js
    end
  end

  def destroy
    @like = Like.find_by(map_id: params[:map_id], user_id: current_user.id)
    @like.destroy
    respond_to do |format|
      format.html { redirect_back(fallback_location: root_path) }
      format.js
    end
  end

  def set_post
    @post = Map.find(params[:map_id])
  end
end
