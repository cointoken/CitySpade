App.Notice =
  init: ->
    this.close()

  close: ->
    banner = $('.notice-banner')
    $('#close-notice').on 'click', ->
      banner.slideUp()
