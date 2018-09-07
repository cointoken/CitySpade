class ClientCheckin
  constructor: ->
    @phoneFormat()
    

  phoneFormat: ->
    $('#client_checkin_phone').on 'input', (e) ->
      x = e.target.value.replace(/\D/g, '').match(/(\d{0,3})(\d{0,3})(\d{0,4})/)
      e.target.value = if !x[2] then x[1] else '(' + x[1] + ') ' + x[2] + (if x[3] then '-' + x[3] else '')
      return

  
  @setup: ->
    new ClientCheckin

App.ClientCheckin = ClientCheckin.setup
