class Accounts
  constructor: ->
    @showPage()

  showPage: ->
    path  = window.location.pathname.split('/')[2]
    $('.menu-item').removeClass('my-style')
    if path == 'saved-wishlist'
      $('#item1').addClass('my-style')
    else if path == 'profile'
      $('#item3').addClass('my-style')

  @setup: ->
    new Accounts

App.Accounts = Accounts.setup
