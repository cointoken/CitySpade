module CurrentCart
  extend ActiveSupport::Concern

    private

      def set_cart
        if session[:temporary_cart].nil?
          session[:temporary_cart] = []
        end
        @cart = session[:temporary_cart]
      end
end
