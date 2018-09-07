App.pc =
  init: ->
    App.Search.init()
    $(".rich-textarea").qeditor({})
    $('.datetimepicker').datetimepicker()
    $('.carousel[auto-carousel!="false"]').carousel()
    App.Validate.init()
    App.Listing.init()
    App.Blog.init()
    App.Review.init()
    App.Notice.init()
    App.UploadifyInit()
    App.BootstrapExtension.init()
    App.SearchMap.init()
    Maps.showMap()
    Maps.neighborhoodStreetView()
    @SubmitDisabled()
    @FixedMap()
    @TouchCarousel()
    @adminDatePicker()
    @adminWeekListingsSelectAll()

    # initialize iPad/GoPro promo modal
    # @adsModal()
   SubmitDisabled: ->
    $('form').bind "ajax:before", (e)->
      #e.preventDefault()
      $(this).find('input[type="submit"]').attr('disabled', true)
     # for submit in $(this).find('input[type="submit"]')
     #submit.val(submit.val()+"...")
    $("form").bind "ajax:success", (e, data, status) ->
      #e.preventDefault()
      $(this).find('input[type="submit"]').attr('disabled', false)

  FixedMap: ->
    ele = document.getElementById('map-fixed-container')
    if ele
      window.pos = ele.getBoundingClientRect()
      top = 20
      obj = $(ele)
      if obj.data('top')
        top = obj.data('top')
      clientTop = pos.top
      if clientTop < 300
        clientTop = 300
      $(window).scroll ->
        if $(window).scrollTop() > clientTop
          obj.addClass('fixed-map')
          obj.css("left", pos.left).css('top', top)
        else
          obj.removeClass('fixed-map')
          obj.css('left', 0).css('top', 0)
  TouchCarousel: ->
    startX = 0
    $('body').delegate '.carousel', 'touchstart', (e) ->
      #e.preventDefault()
      touch = event.targetTouches[0]
      startX = touch.pageX
    $('body').delegate '.carousel', 'touchend', (e) ->
      #e.preventDefault()
      touch = event.changedTouches[0]
      #self = $('#myCarousel')
      self = $(this)
      if(Math.abs(touch.pageX - startX) > 50)
        if touch.pageX > startX
          self.carousel('prev')
        else
          self.carousel('next')
        self.carousel('pause')
  adminDatePicker: ->
    $('.datepicker').datetimepicker({
      format: 'yyyy-mm-dd', autoclose: true, minView: 2, startView: 2
    })

  # Code for iPad/GoPro promo modal
  # adsModal: ->
  #   if !gon.mobiled && gon.has_ads && document.cookie.indexOf('ads_shown=true') < 0
  #     showAds = ->
  #       # 调整上边距
  #       height = $(window).height()
  #       h = (height - 565)*0.5
  #       h = 0 if h < 0
  #       if height - 0.5 * height - 565 < 0
  #         $('#ads-gift').css('top', h - 20 + 'px')
  #       # 调整左边距
  #       width = $(window).width()
  #       w = width - 770
  #       w = 0 if w < 0
  #       if width - 770 > 0
  #         $('#ads-gift').css('left', w*0.5 + 230 + 'px')
  #       $(gon.ads.ele).modal().on 'hidden', ->
  #         d = new Date()
  #         d.setTime(d.getTime() + (2*24*60*60*1000))
  #         #d.setTime(d.getTime() + (2 * 1000))
  #         expires = "expires="+d.toUTCString()
  #         document.cookie = "ads_shown=true;" + expires
  #     if gon.ads.interval
  #       window.setTimeout(showAds, gon.ads.interval)
  #     else
  #       showAds()

  adminWeekListingsSelectAll: ->
    $(".select-all a.btn").click ->
      if $(this).hasClass("select")
        $(this).text("Cancel All")
        $(".check-boxes-div input").prop("checked", true)
        $(this).removeClass("select").addClass("cancel")
      else
        $(this).text("Select All")
        $(".check-boxes-div input").prop("checked", false)
        $(this).removeClass("cancel").addClass("select")
