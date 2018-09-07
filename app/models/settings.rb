class Settings < Settingslogic
  source "#{Rails.root}/config/settings.yml"
  if ['production', 'staging'].include? Rails.env
    namespace Rails.env
  else
    namespace 'production'
  end
end
