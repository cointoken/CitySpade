module Support
  module Session
    def self.included(spec)
      spec.class_eval do
        let(:init_city){ create :city }
        before (:each) { session[:current_city] = init_city }
      end
    end
  end
end
