## common js
window.App = App =
  init: ->
    @CloseDontAlert()
    @AjaxTracking()
    if gon.mobiled
      @MobileInit()
    #@PopupPhoto()
    @InitAjax()
    #@PopupPhoto()
    if @pc
      @pc.init()
    if @mobile
      @pc.init()
  CloseDontAlert: ->
    $("#close-dont-match-info").click ->
      $('#sp-dont-match-search').slideUp()
    $("#miss-match-click-here").click ->
      unless gon.mobiled# && window.MbSearch
        $('#banner-input .multiple-select').multipleSelect("uncheckAll")
        $('#banner-input input[name^="price"]').val('')
        $("#banner-listing-noFee").attr('checked', false)
        $("#listing_title").focus()
    $('a.more-or-less').click ->
      self = $(this)
      if self.attr('data-show') && self.attr('data-hide')
        $(self.attr('data-hide')).hide()
        $(self.attr('data-show')).show('fast')

  MobileInit: ->
    if !gon.logined
      $('a.collect,a.uncollect').click ->
        window.location.href = $(this).attr('href')
        return false
  ## ajax analytics tracking
  AjaxTracking: ->
    old_href = window.location.href
    $(document).bind 'ajax:success', (e, data, status) ->
      e.preventDefault()
      if window.ga && old_href != window.location.href
        ga('send', 'pageview')
  #PopupPhoto: ->
  #  $("a.fancybox").fancybox({type: "image"})
  InitAjax: ->
    if gon.ajax_urls && gon.ajax_urls.length > 0
      for url in gon.ajax_urls
        $.get url
  GetGeoLocation: (callback, error)->
    if navigator.geolocation
      navigator.geolocation.getCurrentPosition(callback, error)
    else
      error()

  AjaxSpinner: ->
    $(document).ajaxStart ->
      $("body").addClass("loading")
    
    $(document).ajaxStop ->
      $("body").removeClass("loading")

  ProfileOverlay: ->
    $('#profile-bttn').click ->
      $('#profile-overlay').show()
      $('body').css("overflow", "hidden")

    $('#profClose').click ->
      $('body').css("overflow", "visible")
      $('#profile-overlay').hide()
