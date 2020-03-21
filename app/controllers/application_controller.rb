class ApplicationController < ActionController::Base
        # エラークラスを定義する
    class Forbidden < ActionController::ActionControllerError; end
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
        render "errors/forbidden", status: 403
    end
    # StandartErrorが会った場合、rescue500メソッドで呼び出される内容
    private def rescue500(e)
        # viewsのerrors/interval_server_errorページを返すよ
        render "errors/internal_server_error", status: 500
    end

end
