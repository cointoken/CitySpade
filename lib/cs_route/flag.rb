module CsRoute
  class Flag
    def self.matches?(req)
      req.params[:flag] =~ /^(sale|rent(al)?)$/i
    end
  end
end
