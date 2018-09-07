Geokit::Geocoders::provider_order=[:google]
# These defaults are used in Geokit::Mappable.distance_to and in acts_as_mappable
Geokit::default_units = :miles
Geokit::default_formula = :sphere
MILE_KM_TRANSLATE = 1.609344
# This is the timeout value in seconds to be used for calls to the geocoder web
# services.  For no timeout at all, comment out the setting.  The timeout unit
# is in seconds.
Geokit::Geocoders::request_timeout = 3
Geokit::Geocoders::MaxmindGeocoder::geoip_data_path = File.join(Rails.root, 'db', 'GeoLiteCity.dat')

Geokit::Geocoders::GoogleGeocoder.client_id = 'gme-cityspade'
Geokit::Geocoders::GoogleGeocoder.cryptographic_key = 'NLp_sAwDDV1A5xYEjzZ_FDSl_4Y='

$geocoder = Geokit::Geocoders::GoogleGeocoder

# This setting can be used if web service calls must be routed through a proxy.
# These setting can be nil if not needed, otherwise, a valid URI must be
# filled in at a minimum.  If the proxy requires authentication, the username
# and password can be provided as well.
# Geokit::Geocoders::proxy = 'https://user:password@host:port'


# This is your Google Maps geocoder keys (all optional).
# See http://www.google.com/apis/maps/signup.html
# and http://www.google.com/apis/maps/documentation/#Geocoding_Examples
# Geokit::Geocoders::GoogleGeocoder.client_id = ''
# Geokit::Geocoders::GoogleGeocoder.cryptographic_key = ''
# Geokit::Geocoders::GoogleGeocoder.channel = ''

