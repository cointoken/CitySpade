# encoding: utf-8

##
# Backup Generated: cityspade_db
# Once configured, you can run the backup with the following command:
#
# $ backup perform -t cityspade_db [-c <path_to_configuration_file>]
#
# For more information about Backup's components, see the documentation at:
# http://meskyanichi.github.io/backup
#
Model.new(:cityspade_db, 'Backup CitySpade DB') do

  ##
  # MySQL [Database]
  #
  database MySQL do |db|
    # To dump all databases, set `db.name = :all` (or leave blank)
    db.name               = "cityspade_production"
    db.username           = "root"
    db.port               = 3306
    # db.socket             = "/tmp/mysql.sock"
    # Note: when using `skip_tables` with the `db.name = :all` option,
    # table names should be prefixed with a database name.
    # e.g. ["db_name.table_to_skip", ...]
    #db.skip_tables        = ["skip", "these", "tables"]
    #db.only_tables        = ["only", "these", "tables"]
    db.additional_options = ["--quick", "--single-transaction"]
  end

  ##
  # SCP (Secure Copy) [Storage]
  #
  store_with SCP do |server|
    server.username   = "ec2-user"
    server.password   = ""
    server.ip         = "test.cityspade.com"
    server.port       = 22
    server.path       = "~/backups/"
    server.keep       = 5

    # Additional options for the SSH connection.
    # server.ssh_options = {}
  end

  store_with Dropbox do |db|
    db.api_key     = "ytld4m3vp0n235h"
    db.api_secret  = "ndp7ibhftnpt8b3"
    # Sets the path where the cached authorized session will be stored.
    # Relative paths will be relative to ~/Backup, unless the --root-path
    # is set on the command line or within your configuration file.
    db.cache_path  = ".cache"
    # :app_folder (default) or :dropbox
    db.access_type = :app_folder
    db.path        = "~/backups"
    db.keep        = 25
  end
  ##
  # GPG [Encryptor]
  #
  # Setting up #keys, as well as #gpg_homedir and #gpg_config,
  # would be best set in config.rb using Encryptor::GPG.defaults
  #
  #  encrypt_with GPG do |encryption|
  ## Setup public keys for #recipients
  #encryption.keys = {}
  #encryption.keys['user@domain.com'] = <<-KEY
  #-----BEGIN PGP PUBLIC KEY BLOCK-----
  #Version: GnuPG v1.4.11 (Darwin)

  #<Your GPG Public Key Here>
  #-----END PGP PUBLIC KEY BLOCK-----
  #KEY

  ## Specify mode (:asymmetric, :symmetric or :both)
  #encryption.mode = :both # defaults to :asymmetric

  ## Specify recipients from #keys (for :asymmetric encryption)
  #encryption.recipients = ['user@domain.com']

  ## Specify passphrase or passphrase_file (for :symmetric encryption)
  #encryption.passphrase = 'a secret'
  ## encryption.passphrase_file = '~/backup_passphrase'
  #end
  encrypt_with OpenSSL do |encryption|
    encryption.password = 'cityspade@gz'
    encryption.base64   = true
    encryption.salt     = true
  end
  ##
  # Gzip [Compressor]
  #
  compress_with Gzip

  ##
  # Mail [Notifier]
  #
  # The default delivery method for Mail Notifiers is 'SMTP'.
  # See the documentation for other delivery options.
  #
  notify_by Mail do |mail|
    mail.on_success           = true
    mail.on_warning           = true
    mail.on_failure           = true

    mail.from                 = "cityspade@gmail.com"
    mail.to                   = "cityspade@gmail.com"
    mail.address              = "smtp.gmail.com"
    mail.port                 = 587
    mail.domain               = "gmail.com"
    mail.user_name            = "cityspade@gmail.com"
    mail.password             = "cityspade@nyc"
    mail.authentication       = "plain"
    mail.encryption           = :starttls
  end

end
