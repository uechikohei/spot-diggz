class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception
    before_action :configure_permitted_parameters, if: :devise_controller?
    before_action :set_search

    def set_search
      @maps = Map.all
      @map_key = Map.ransack(params[:q])
      @search_maps = @map_key.result(distinct: true).page(params[:page])
      @users = User.all
      @user_key = User.ransack(params[:q])
      @search_feeds = @user_key.result(distinct: true).page(params[:page])
    end

  protected

    def after_sign_up_path_for(resource)
      edit_user_registration_path
    end

    def configure_permitted_parameters
      devise_parameter_sanitizer.permit(:sign_up,        keys: [:name])
      devise_parameter_sanitizer.permit(:sign_up,        keys: [:image])
      devise_parameter_sanitizer.permit(:account_update, keys: [:name])
      devise_parameter_sanitizer.permit(:account_update, keys: [:image])
    end
    # エラークラスを定義する
    class Forbidden         < ActionController::ActionControllerError; end
    class IpAddressRejected < ActionController::ActionControllerError; end

    # rescue_formは定義順番が大事。親クラスを先に指定。
    # StandartErrorがあったら、rescue500メソッドを呼び出す
    rescue_from StandardError, with: :rescue500
    # Forbiddenエラーがあったら、resuvue403メソッドを呼び出す
    rescue_from Forbidden, with: :rescue403
    # IPアドレス制限によるアクセス拒否があれば、rescue403メソッドを呼び出す
    rescue_from IpAddressRejected, with: :rescue403

    # Forbiddenエラーがあったときに呼び出されるメソッド
    private def rescue403(e)
      @exception = e
      logger.error "error_404: #{e.message}"
      logger.error e.backtrace.join("\n")
      render "errors/forbidden", status: 403
    end
    # StandartErrorが会った場合、rescue500メソッドで呼び出される内容
    private def rescue500(e)
      # viewsのerrors/interval_server_errorページを返すよ
      logger.error "error_404: #{e.message}"
      logger.error e.backtrace.join("\n")
      render "errors/internal_server_error", status: 500
    end
end
