class LikesController < ApplicationController

  def create
    @like = current_user.likes.create(map_id: params[:map_id])
    @like.save
  end

  def destroy
    @like = Like.find_by(map_id: params[:map_id], user_id: current_user.id)
    @like.destroy
  end

end
