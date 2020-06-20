class CommentsController < ApplicationController
  def create
    @map = Map.find(params[:map_id]) #①コメントをする対象の投稿(map)のインスタンスを作成します
    @comment = @map.comments.build(comment_params) #②buildで、@mapのidをmap_idにh組んだ形でcommentインスタンス作成
    @comment.user_id = current_user.id #③現在のuserのidを入れます
    @comments = @comment.map.comments
    #④保存、render :indexによって「app/views/comments/index.js.erb」を探しにいきます。
    @comment.save
    respond_to do |format|
      format.html { redirect_back(fallback_location: root_path) } # この中はHTMLリクエストの場合に呼ばれる
      format.js { render :index } # この中はJSONリクエストの場合に呼ばれる
    end
  end

  def destroy
    @comment = Comment.find(params[:id]) #⑤削除する対象のコメントインスタンスを探します。
    @comments = @comment.map.comments
    @comment.destroy
    respond_to do |format|
      format.html { redirect_back(fallback_location: root_path) } # この中はHTMLリクエストの場合に呼ばれる
      format.js { render :index } # この中はJSONリクエストの場合に呼ばれる
    end
  end

  private
    def comment_params
      params.require(:comment).permit(:content, :map_id, :user_id)
    end
end
