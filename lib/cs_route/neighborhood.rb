module CsRoute
  class Neighborhood
    def self.matches?(req)
      req.params[:neighborhood] !~ /^for-/
    end
  end
end
