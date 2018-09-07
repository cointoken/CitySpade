App.Listing =
  init: ->
    this.signModal()
    this.ratingActive()
    this.getCheckedDo()
    this.moreReview()
    this.improveCarousel()
    this.mortgage()
    this.choseBrokerFee()
    this.calApartAttrDescription()
    $("select[name='listing[beds]']").selectize()
    $("select[name='listing[baths]']").selectize()
    this.limitEndDateInput()
    this.showFloorplan()

    #this.isOpenHouse()
  signModal: ->
    # sign up and sign in 弹框 modal
    $(".modal-body form.new_account").bind "ajax:success", (e,data,status)->
      if data.success
        if data.redirect_to
          if $("#review-show-share4").length > 0
            $('.modal').modal('hide')
            $("#review-show-share4").modal('show')
            $("#review-show-share3").modal('hide')
            $("#to_review_your_page").attr('href', data.redirect_to)
          else
            window.location.href = data.redirect_to
            #location.reload()
        else
          location.reload()
      else
        $(".sign_in_content #account_email").next(".error_info").text("email or password was error, your account would be locked for failure to log in for 5 times.").addClass(".error_info_border")

  # search page
  ratingActive: ->
    $(".sort-input.rating a, .sort-input.price a").click ->
      $(".sort-input.rating a, .sort-input.price a").removeClass("active")
      $(this).addClass('active')
    $(".sort-input.reset a").click ->
      $(".sort-input.rating a, .sort-input.price a").removeClass("active")
  ## list_with_us

  getChecked: (idName,other) ->
    $("#"+ idName).click ()->
      $("label[for="+ other + "]").attr('class','')
      $("label[for="+ idName + "]").attr('class','checked')
      if $('label[for="yes"]').attr('class') == "checked"
        $("#specify").parent().attr('style','display:block')
      else
        $("#specify").parent().attr('style','display:none')

  getCheckedDo: ->
    this.getChecked("agent","manager")
    this.getChecked("manager","agent")
    this.getChecked("noFee","brokerFee")
    this.getChecked("brokerFee","noFee")
    this.getChecked("yes","no")
    this.getChecked("no","yes")

  moreReview: ->
    $("#related-reviews .more").click ->
      console.log this
      self = $(this)
      currentSpan = self.parent().parent('.related-reviews-span')
      if self.html() == 'Read More'
        $(".related-reviews-span .review-lock-tmp").hide()
        $(".related-reviews-span .pc-hide-lock").show()
        self.html("Less")
        currentSpan.find('.more-review-list').show('slow')
      else
        $(".related-reviews-span .review-lock-tmp").show()
        $(".related-reviews-span .pc-hide-lock").hide()
        self.html("Read More")
        currentSpan.find('.more-review-list').hide('slow')

  improveCarousel: ->
    if $('.carousel-inner.image-pannel iframe').length > 0
      $("#listingGallery.carousel").carousel('pause')
      $('#listingImagesCarousel').carousel('pause')
      div = document.getElementById("popupVid").getElementsByTagName("iframe")[0]
      $('a.carousel-control.left').click ->
        div.contentWindow.postMessage('{"event":"command","func":"' + 'pauseVideo' + '","args":""}','*')
      $('a.carousel-control.right').click ->
        div.contentWindow.postMessage('{"event":"command","func":"' + 'pauseVideo' + '","args":""}','*')
    else
      $("#listingGallery.carousel").on 'slid.bs.carousel', (e, i) ->
        index = $(this).find('.item.active a').attr("data-img-index")
        page = parseInt index / 4
        imgList = $('#listingImagelist ul.item[data-img-page=' + page + ']')
        unless imgList.hasClass('active')
          $("#listingImagelist ul.item").removeClass('active')
          imgList.addClass('active')
        $("#listingImagelist li").removeClass('current-img')
        $("#listingImagelist li.img-index-"+index).addClass('current-img')

  mortgage: ->
    return if $("#mortgage-calculator").length == 0
    calPayment = (e, t, n)->
      e * t / (1 - Math.pow(1 + t, -n))
    calMortgage = ->
      price = $('#mortgage-price').val()
      term  = $("#mortgage-term").val()
      downpayment = $("#mortgage-downpayment").val()
      rate = $("#mortgage-rate").val()
      price = price.replace(/\,/g, '')
      if isNaN(price) || isNaN(term) || isNaN(downpayment) || isNaN(rate)
        return
      price = parseInt(price)
      $("#mortgage-price").val(price.format())
      term  = parseInt term
      downpayment = parseInt(downpayment) / 100
      rate = parseFloat(rate) / 100
      downpayment_amount = price * downpayment
      mortgage_amount = price - downpayment_amount
      common_charge = parseInt $('#common-charges').html().replace(/\D/g, '')
      mortgage_payment = calPayment mortgage_amount, rate / 12, term * 12
      mortgage_monthly = mortgage_payment + common_charge
      $("#downpayment-amount").html("$" + downpayment_amount.format())
      $("#mortgage-amount").html('$' + mortgage_amount.format())
      #$('#common-charge').html('$' + common_charge.format())
      $('#mortgage-payment').html('$' + mortgage_payment.format())
      $('#mortgage-monthly-price').html('$' + mortgage_monthly.format())
    calMortgage()
    $("input.mortgage,select.mortgage").change ->
      calMortgage()

  choseBrokerFee: ->
    $("#costs-and-requirements .broker_fee .chose-btn").bind "click", (e) ->
      price = parseInt($(".first_rent").text().replace(/\D/g,""))
      brokerFeeTotal = price * 12
      if $(this).text() == "10%"
        brokerFeeTotal = brokerFeeTotal * 0.1
      else if $(this).text() == "15%"
        brokerFeeTotal = brokerFeeTotal * 0.15
      else
        brokerFeeTotal = price
      total = brokerFeeTotal + price * 2
      $(".broker_fee .chose-btn").removeClass("chosen")
      $(this).addClass("chosen")
      $(".broker_fee_price").text("( $" + brokerFeeTotal.format() + " )")
      $("table .total").text("( $" + total.format() + " )")

  calApartAttrDescription: ->
    $("#listing_listing_detail_attributes_description").bind "keyup", (e)->
      e.preventDefault()
      len = $(this).val().length
      $(".cal-characters .cal-char").text(len)

  limitEndDateInput: ->
    $(".datepicker").datetimepicker(
      minView: 2
      autoclose: true
      pickTime: false
      format: "yyyy-mm-dd"
      todayBtn: true
    ).on "changeDate", (ev) ->
      begintime = $("#listing_available_begin_at").val()
      $("#listing_available_end_at").datetimepicker "setStartDate", begintime
      $("#listing_available_begin_at").datetimepicker "hide"

  showFloorplan: ->
    $(".floorplan-btn").on "click", (e)->
      unless $(this).parents(".item").hasClass("floorplan")
        # The big photo
        e.preventDefault()
        $("#listingGallery .item").removeClass("active")
        floorplan = $($(".item.floorplan")[0])
        floorplan.addClass("active")
        # The small photo
        index = floorplan.find("a.listing-image").data("img-index")
        $("#listingImagelist .item").removeClass("active")
        currentImg = $("#listingImagelist .item .img-index-" + index)
        currentImg.parents("ul.item").addClass("active")
        currentImg.addClass("current-img")

class ListingItem
  constructor: ->
    @fancyboxInit()
    @videoIconTooltip()

  fancyboxInit: ->
    $("a.fancybox-preview").attr("rel", "gallery").fancybox
      type: "ajax"
      wrapCSS: "listing-fancybox"
      width: 500
      autoSize: false
      autoScale: false
      autoDimensions: false
      padding: 0
      loop: false
      fitToView: false

      beforeShow: -> # disable scrolling on body
        $("body").css({'overflow':'hidden'})

      afterClose: -> # enable scrolling on body
        $("body").css({"overflow":"visible"})

      keys: {
        play: [] # prevent slideshow mode when [space key] is pressed
      }

  videoIconTooltip: ->
    $('.fa-video-camera').tooltip
      title: 'Video Tour available'
      placement: 'right'

  @setup: ->
    new ListingItem

App.ListingItemSetup = ListingItem.setup
