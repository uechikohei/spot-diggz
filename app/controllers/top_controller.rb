class TopController < ApplicationController
    def index
        # raise
        # raise Forbidden
        # raise IpAddressRejected
        # productionモードで起動することで、例外処理を起こせる。
        render action "index"
    end
end