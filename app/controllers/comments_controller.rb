class CommentsController < ApplicationController
  before_action :set_micropost, only: %i[create destroy]

  def create
    @comment = @map.comments.build(comment_params)
    @comment.user_id = current_user.id
    @comment.save
  end

  def destroy
    @comment = Comment.find(params[:id])
    @comment.destroy
  end

  private

    def set_micropost
      @map = Map.find(params[:map_id])
    end

    def comment_params
      params.require(:comment).permit(:content, :map_id, :user_id)
    end
end
