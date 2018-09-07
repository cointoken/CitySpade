require 'sidekiq/web'
CitySpade::Application.routes.draw do
  # agent relative
  resources :rooms do
   collection do
     match :send_message, via: [:post, :get]
     match :save_wishlist, via: [:post, :get]
     post :expire
   end
  end

  #resources :flashsales, path: "dailydeals" do
  #end

  resources :building_pages, path: "buildings" do
    post :send_message
    collection do
      match :favorite, via: [:post, :get]
    end
  end
  get '/buildingsearch' => 'building_pages#search'

  get 'alldeals' => 'rentaldeals#all_deals'
  match 'bookshowing', to: 'rentaldeals#book_showing', via: [:post, :get]
  get 'cookielistings' => 'rentaldeals#cookie_listings', as: 'cookielist'

  #get 'guarantors' => 'guarantors#index'


  resources :search_for_me, path: "searchforme" do
  end

  resources :wolftest, path: "wolftest" do
  end

  #get '/dealmoon' => 'search_for_me#refer_dealmoon'

  #resources :client_checkins, path: "checkin" do
  #end

  #get 'owners/new'

  #get 'owners/create'

  #get 'owners/update'

  #get 'owners/edit'

  #get 'owners/destroy'

  get 'mail_notifies/unsubscribe', as: :unsubscribe_mail_notify

  get '/roomsearch', to: 'room_search#index'

  get '/apply' => 'client_apply#new'
  match '/apply/create' => 'client_apply#create', via: [:get, :post]
  get '/apply/confirm/:id' => 'client_apply#show', as: 'apply_confirm'
  get '/apply/retrieve' => 'client_apply#retrieve', as: 'apply_retrieve'
  match '/apply/edit' => 'client_apply#edit', as: 'apply_edit', via: [:get, :post]
  match '/apply/update' => 'client_apply#update', as: 'apply_update', via: [:put, :patch]
  delete '/apply/:id' =>  'client_apply#destroy', as: 'apply_destroy'
  post '/apply/payment' => 'client_apply#card_payment'
  get '/apply/appfee' => 'client_apply#app_fee'
  get '/apply/deposit/:id' => 'client_apply#deposit', as: 'apply_deposit'
  put '/apply/dep_payment' => 'client_apply#deposit_payment'
  get '/cutedivide' => 'client_apply#cute_divide'
  post '/cutedividepayment' => 'client_apply#cutedivide_payment'
  get '/aboutus' => 'aboutus#index'

  resources :roommates do
   collection do
     match :send_message, via: [:post, :get]
     post :expire
   end
  end

  #resources :photos do
  #  collection do
  #    get :uploaded_photos
  #    post :uploadify
  #    get :photos_info
  #  end
  #end
  #resources :reviews do
  #  collection do
  #    get :result
  #    get :photos
  #    get :nearby_venues
  #  end
  #  member do
  #    get :collect
  #    get :uncollect
  #    get :related_apartments
  #  end
  #end
  #### fix conflict on reviews/:id/collect, after resources reviews
  #get 'reviews/:review_type/:permalink', to: 'reviews#show', as: :venue#, constraints: {review_type: /^[a-z].+/ }
  #get 'reviews/:review_type/:permalink/:id', to: 'reviews#show', as: :venue_review#, constraints: {review_type: /^\D/}

  #resources :list_with_us, only: [:new, :create]
  #resources :owners, only: [:new, :create]
  resources :agents, only: [:show, :index]
  post '/agents/contact-agent', to: "agents#contact_agent"
  #get 'list_with_us' => 'list_with_us#new'
  #get 'owners' => 'owners#new'

  #get 'mls/test' => "mls#test"
  #get 'mls/status/:mls_name' => "mls#status"
  #get 'mls/reports/:mls_name' => 'mls#reports', format: :xml
  #get 'mls/:mls_name/listings/:provider_id' => 'mls#mls_back', as: :mls_back
  #get 'mls/:mls_name/:broker_name/:mls_id' => "mls#index", as: :mls_listing
  #get 'mls/nestio' => "mls#nestio"
  #get 'mls/nestio/:mls_name' => "mls#nestio_listings", as: :nestio_listings
  #get 'mls/broker' => "mls#broker"
  #get 'mls/broker/:broker_id' => "mls#broker_listings", as: :broker_listings

  #get "listings/index"
  #get "fancybox_listings/:id/", to: "listings#fancybox_content", as: "fancybox_listing"

  #get 'mls/general' => "mls#general"
  #get 'mls/general/:mls_name' => "mls#general_listings", as: :general_listings
  #get 'mls/:mls_name' => 'mls#rentlinx', as: :mls_rentlinx
  #get 'mls/:mls_name/:broker_name' => "mls#rentlinx_listings", as: :rentlinx_listings
  #get 'download_csv' => "mls#download_csv", as: :realtymx_csv
  resources :inboxes, only: [:show, :index]
  resources :account_inboxes, only: [:destroy]

  devise_for :accounts,
    :controllers => { :omniauth_callbacks => "omniauth_callbacks", :registrations => "registrations", :sessions=> :sessions  },
    :path=> '', :path_names => {:sign_in => '/log_in', :sign_out => '/logout'}

  devise_scope :account do
    get 'account/profile', to: 'registrations#edit', as: :edit_account
  end

  authenticate :account, lambda { |u| u.admin? }  do
    mount Sidekiq::Web => '/sidekiq'
  end

  #get 'OpenHouses' => 'search#open_houses', as: :open_houses
  #get "search/autocomplete"
  #get "search/set_current_area", to: 'search#set_current_area'#, as: :search_area_neighborhood #=> searc_neigborhood_path(name)
  #get "search/map" => 'search#map', as: :search_map
  #get "search/map/for-:flag" => 'search#map', as: :search_map_flag, constraints: CsRoute::Flag
  #match "search/index", via: [:get, :post], as: :search
  #get 'search/for-:flag' => 'search#index', as: :flag_search, constraints: CsRoute::Flag
  #get "search/neighborhoods/:neighborhood", to: 'search#index', as: :search_neighborhoods , constraints: CsRoute::Neighborhood
  #get 'search/:current_area/index' => 'search#index', as: :area_index_search
  #get 'search/:current_area/for-:flag' => 'search#index', as: :area_search, constraints: CsRoute::Flag
  #get "search/:current_area/:neighborhood", to: 'search#index', as: :search_area_neighborhood, constraints: CsRoute::Neighborhood

  #get "home/index"
  get "/account", to: "accounts#show"
  #get "/accounts/verify_office", to: "accounts#verify_office"

  #get "/authenticate", to: "accounts#authenticate"

  get "/account/listings/for-:status", to: "accounts#listings", as: :account_listings, constraints: CsRoute::Status
  get "/account/check_facebook_login", to: "accounts#check_facebook_login", as: :check_facebook_login
  get "/account/saved-wishlist/for-:flag", to: "accounts#saved_wishlist", as: :account_saved_wishlist, constraints: CsRoute::Flag
  get "/account/past-wishlist/for-:flag", to: "accounts#past_wishlist", as: :account_past_wishlist, constraints: CsRoute::Flag
  get "account/room-wishlist", to: "accounts#room_wishlist", as: :account_room_wishlist
  get "account/my-postings", to: "accounts#my_room_postings", as: :account_myrooms
  get "account/applications", to: "accounts#applications", as: :account_applications

  #get '/demo/listings.xml' => 'home#demo'

  #resources :listings do
  #  member do
  #    get :collect
  #    get :uncollect
  #    get :nearby_reviews
  #    get :nearby_homes
  #    get :expire
  #    get :refresh
  #  end
  #  collection do
  #    get :nearby_venues
  #    get :neighborhoods
  #    get :photos
  #    match :send_message, via: [:post, :get]
  #    match :flash_email, via: [:post, :get]
  #  end
  #end

  #resources :blogs, path: 'blog' do
  #  collection do
  #    get ':year/:month/:day/:id', :action => 'show',
  #      :year => nil,
  #      :month => nil,
  #      :day => nil,
  #      :requirements => {:year => /\d{4}/,
  #                        :month => /\d{2}/,
  #                        :day => /\d{2}/}, as: :day
  #  end
  #end
  #get 'neighborhoods', to: 'listings#neighborhoods', as: :neighborhoods
  #get 'neighborhoods/:current_area', to: 'listings#neighborhoods', as: :current_area_neighborhoods

  root 'home#index'
  get '/universities' => "home#universities"
  #root 'search_for_me#new'
  #get 'download' => "home#download"

  get "sitemap.xml" => "home#sitemap", format: :xml, as: :sitemap
  get "robots.txt" => "home#robots", format: :text, as: :robots

  namespace :admin do
    root :to => 'welcome#index'
    resources :welcome do
      collection do
        get 'restart_sidekiq'
        get 'download_log'
        get 'building_cleanup'
      end
    end
    resources :inboxes
    resources :blogs
    resources :brokers
    resources :agents
    resources :accounts, expect: [:show, :destroy]
    resources :photos, only: [:index, :destroy]
    post 'photos' => 'photos#index'
    resources :reviews, expect: [:show, :destroy, :create]
    resources :buildings, expect: [:destroy] do
      member do
        get :relate_listings
      end
    end
    resources :listings, only: [:index, :destroy] do
      collection  do
        match :no_fee_management, via: [:get, :post]
      end
    end
    resources :search_records, only: [:index, :destroy]
    resources :week_listings, only: [:index]
    resources :page_views, only: [:index]
    resources :political_areas, except: [:show, :create]
    resources :search_for_mes, path: "searchforme", only: [:index, :destroy]
    get '/searchforme/sendemail' => 'search_for_mes#send_email'
    resources :client_checkins, path: "checkin", only: [:index]
    get '/bookings' => 'client_checkins#book_showing', as: 'bookings'
    resources :client_apply, path: "apply", only: [:index, :destroy, :edit] do
      member do
        patch :update, path: 'update', as: 'apply_update'
      end
    end
    resources :transport_places, except: [:show, :create]
    resources :building_pages, path: "buildinglist", only: [:index] do
      member do
        get :add_images, path: 'addimages'
        post :create_images, path: 'createimages'
        get :add_floorplan, path: 'addfplans'
        post :create_floorplan, path: 'createfplans'
        delete :delete_bimage, path: 'delbimage'
        delete :delete_fplan, path: 'delfplan'
        match :edit_fplan, via: [:get, :put]
        get :set_cover, path: 'setcover'
      end
    end
    post '/mailbuilding' => 'client_apply#mail_building'
    get '/mailtemplate' => 'client_apply#mail_template'
    get '/autocomplete' => 'client_apply#autocomplete'
    get '/doc-size' => 'client_apply#doc_size'
    patch '/changestatus' => 'client_apply#change_app_status', as: 'change_app_status'
    resources :contact_emails
    resources :rooms do
      member do
        post 'expire'
      end
    end
    resources :roommates do
      member do
        post 'expire'
      end
    end
    resources :spade_passes do
      member do
        get :add_images, path: 'addimages'
        post :create_images, path: 'createimages'
        delete :delete_image, path: 'delimage'
        get :set_cover
      end
    end
    resources :careers
  end


  resources :services, only: [:index] do
  end

  resources :careers
  #get '/careers/fin-analyst' => 'careers#fin_analyst'
  #get '/careers/translators' => 'careers#translators'
  #get '/careers/reg-affairs' => 'careers#reg_affairs'
  #get '/careers/app_restate' => 'careers#app_restate'
  #get '/careers/cs-analyst' => 'careers#cs_analyst'
  #get '/careers/budget-analyst' => 'careers#budget_analyst'
  #get '/careers/business-analyst' => 'careers#business_analyst'
  #get '/careers/or-analyst' => 'careers#or_analyst'
  #get '/careers/it-proj' => 'careers#it_proj'
  #get '/careers/market-analyst' => 'careers#market_analyst'
  #get '/careers/accountant' => 'careers#accountant'
  #get '/careers/graphic-design' => 'careers#graphic_design'
  #get '/careers/business_develop' => 'careers#business_develop'
  #get '/careers/pubic-relation' => 'careers#pub_relation'
  #get '/careers/data-analyst' => 'careers#data_analyst'
  #get '/careers/manage-analyst' => 'careers#manage_analyst'

  resources :contacts
  get '/contact', to: 'contacts#new', as: :contact_us

  namespace :api, { :formats => [:json, :js] } do
    #get 'geoip' => 'geoip#index'
    #get 'geoip/outdoor' => 'geoip#outdoor', as: :geoip_outdoor
    #get  'listings' => 'listings#index'
    #get 'listings/map' => 'listings#map'
    #get 'listings/map/for-:flag' => 'listings#map', constraints: CsRoute::Flag
    #resources :places do
    #  collection do
    #    get :cities
    #    get :states
    #    get :autocomplete
    #    get :any_neighborhoods
    #    post :set_city
    #    get :coordinates
    #  end
    #end
    namespace :v1 do
      #resources :listings do
      #  member do
      #    match :collect, via: [:get, :post]
      #    delete :uncollect
      #  end
      #end
      resources :auth do
        collection do
          post 'login'#, via: [:post, :get]
          delete 'logout'#, via: [:post, :delete]
          post 'register'#, via: [:post, :get]
          get 'forget_password'
          post 'callback'
        end
      end
      get 'account/savinglists'
    end
    namespace :v2 do
      #resources :listings do
      #  member do
      #    match :collect, via: [:get, :post]
      #    delete :uncollect
      #  end
      #  collection do
      #    get 'cities'
      #    get 'simple'
      #  end
      #end
      resources :auth do
        collection do
          post 'login'#, via: [:post, :get]
          delete 'logout'#, via: [:post, :delete]
          post 'register'#, via: [:post, :get]
          get 'forget_password'
          post 'callback'
        end
      end
      get 'account/savinglists'
    end

    namespace :mini_wechat do
      resources :building_pages do
        collection do
          get 'uncollect_building'
          get 'collect_building'
        end
      end
      resources :mini_wechat_users do
        collection do
          get 'auth'
          get 'check_current_user'
          get 'new'
          get 'my_collect_buildings'
          get 'my_collect_spade_passes'
          post 'set_user_info'
        end
      end
      resources :spade_passes do
        collection do
          get 'recommend_spade_passes'
          get 'collect_spade_pass'
          get 'uncollect_spade_pass'
        end
      end
    end

  end

  resources :pages
  get ':id', to: 'pages#show', as: :static_page
end
