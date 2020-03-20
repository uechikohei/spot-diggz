module ApplicationHelper
    # インスタンス変数@titleが空でなければ、それに「SkateSpotSearch」という文字列を追加して返すだけの簡単なメソッド
    def document_title
        if @title.present?
            "#{@title} - SkateSpotSearch"
        else
            "SkateSpotSearch"
        end
    end
end
