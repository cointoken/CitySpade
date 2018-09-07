class FlashsaleIndex
  constructor: ->
    @dropLogic()

  dropLogic: ->
    selected = $('#flashdrop li .active').text()
    if selected
      $('#flashdrop button').html(selected + ' <span class="caret"></span>')

  @setup: ->
    new FlashsaleIndex

App.FlashsaleIndex = FlashsaleIndex.setup
