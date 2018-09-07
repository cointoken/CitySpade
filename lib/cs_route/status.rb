module CsRoute
  class Status
    def self.matches?(req)
      req.params[:status].match(/^(actived|expired)$/i)
    end
  end
end
