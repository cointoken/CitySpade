class OpenHouses
  constructor: ->
    @infiniteScroll()

  infiniteScroll: ->
    $('#openHousePagination').infinitePages
      buffer: 10
      loading: ->
        $(@).text('Loading next page...')
      success: ->
        $(@).text('')
      error: ->
        $(@).button('There was an error, please try again')

  @setup: ->
    new OpenHouses

$(document).ready ->
  OpenHouses.setup()
