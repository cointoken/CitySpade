App.Validate =
  init: ->
    this.validateAccount()
    this.validateContact()
    this.validateReview()

  validateAccount: ->
    $("#new_account").validate
      rules:
        "account[first_name]":
          required: true
        "account[last_name]":
          required: true
        "account[email]":
          required: true,
          email: true
        "account[password]":
          required: true
        "account[password_confirmation]":
          required: true,
          equalTo: "#account_password"

  validateContact: ->
    $("#new_contact").validate
      rules:
        "contact[name]":
          required: true
        "contact[subject]":
          required: true
        "contact[message]":
          required: true
        "contact[email]":
          required: true,
          email: true

  validateListWithUs: ->
    $("#new_list_with_us").validate
      rules:
        "list_with_us[email]":
          required: true,
          email: true
        "list_with_us[contact_number]":
          required: true,
          number: true

  validateReview: ->
    $("#new_review").validate()
