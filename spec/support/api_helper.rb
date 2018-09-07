require 'active_support/all'
module Api
  module Helper
    def api_json
      @json ||= JSON.parse(response.body)
    end
    def api_get(action, params={}, session=nil, flash=nil)
      api_process(action, params, session, flash, "GET")
    end

    def api_post(action, params={}, session=nil, flash=nil)
      api_process(action, params, session, flash, "POST")
    end

    def api_put(action, params={}, session=nil, flash=nil)
      api_process(action, params, session, flash, "PUT")
    end

    def api_delete(action, params={}, session=nil, flash=nil)
      api_process(action, params, session, flash, "DELETE")
    end

    def api_process(action, params={}, session=nil, flash=nil, method="get")
      scoping = respond_to?(:resource_scoping) ? resource_scoping : {}
      process(action, method, params.merge(scoping).reverse_merge!(:use_route => :spree, :format => :json), session, flash)
    end

    def current_city
      current_city ||= City.where(name: 'New York', state: 'NY', country: 'US').first
      current_city
    end

    def current_area
      @current_area ||= begin
                          if session[:current_area_id]
                            PoliticalArea.find session[:current_area_id]
                          else
                            if current_city && current_city.state == 'PA'
                              PoliticalArea.philadelphia
                            else
                              PoliticalArea.default_area
                            end
                          end
                        end
    end

  end
end
