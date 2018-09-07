module Support
  module Login
    def self.included(spec)
      spec.class_eval do
        let(:account){ create :account}

        before(:each) do
          account
          visit '/log_in'
          within '#new_account' do
            fill_in 'account_email', with: account.email
            fill_in 'account_password', with: 'password'
            click_button 'Log in'
          end
          page.should have_content account.first_name
        end
      end
    end
  end
end
