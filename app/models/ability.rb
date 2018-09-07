class Ability
  include CanCan::Ability

  def initialize(account)
    account ||= Account.new
    alias_action :edit, :update, :destroy, :to => :operate
    alias_action :result, :to => :read
    alias_action :collect, :uncollect, to: :like
    if account.role? :admin
      can :manage, :all
    elsif account.role? :editor
      can :manage, :all
      cannot :operate, [Blog] do |blog|
        blog.account != account
      end
      cannot :operate, Page
    elsif account.role? :office
      can :manage, Listing
      can :operate, Listing do |listing|
        #listing.account == account
      end
    elsif account.present?
      can :read, :all
      can :manage, Review
      can :like, Review
      cannot :operate, [Review] do |review|
        # (!account.role?(:admin) && review.account != account)
        !account.role?(:admin)
      end
      cannot [:create, :edit], Listing
      cannot [:operate, :read], Contact
      can :create, ListWithUs
    else
      can :read, :all
      cannot [:operate], Listing
      cannot :read, Account
      cannot [:create, :operate], Review
      can :create, ListWithUs
    end

    can [:send_message, :flash_email, :collect, :uncollect, :neighborhoods,
         :nearby_venues, :nearby_reviews, :nearby_homes, :fancybox_content],
         Listing
  end
end
