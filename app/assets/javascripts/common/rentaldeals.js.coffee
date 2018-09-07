class Rentaldeals
  constructor: ->
    @cartItems()
    @saveIds()
    @bookShowing()
    @cookieListings()
    @checkTime()
    @displayTime()
    @errorCheck()
    @removeApt()
    @viewCart()
    @modalShow()
    @fancyBox()

  cartItems: ->
    if checkCookie()
      $('#cart-button span').text(0)
    else
      items = $.cookie('listing_ids').split(',')
      $('#cart-button span').text(items.length)

  checkCookie = ->
    if((typeof($.cookie('listing_ids')) == 'undefined') || ($.cookie('listing_ids')==""))
      return true
    else
      return false


  saveIds: ->
    if checkCookie()
      listids=[]
    else
      listids = $.cookie('listing_ids').split(",")
    $('.add-to-cart').on 'click', ->
      date = new Date()
      mins = 60
      date.setTime(date.getTime() + (mins * 60 * 1000))
      listids.push($(this).data('id'))
      $.cookie('listing_ids', listids, { expires: date })
      $(this).addClass('transform-button')
      $(this).one 'webkitTransitionEnd otransitionend oTransitionEnd msTransitionEnd transitionend', ->
        curr=$(this)
        cart = $('#cart-button')
        flybutton = curr.eq(0)
        btnclone = flybutton.clone().offset(
          top: flybutton.offset().top
          left: flybutton.offset().left
        ).css(
          'position':'absolute'
          'height':'60px'
          'width':'50px'
          'z-index':'100'
          'border-radius': '50%'
          'font-size':'0'
          'background':'#2fcdc9'
        ).appendTo('body').animate({
        'top': cart.offset().top+15
        'left': cart.offset().left+15
        'width': '30px'
        'height': '30px'
        'border-radius': '50%'
        'z-index':'9999999'
        }, 500, 'linear')
        btnclone.animate {
          'width':0
          'height':0
        }, ->
          $(this).detach()
          items = $.cookie('listing_ids').split(',')
          $('#cart-button span').text(items.length)
          $(curr).hide()
          msg = $(curr).parent().find(".cart-msg")
          if msg.length
            msg. show()
          else
            $(curr).parent().append("<p class='cart-msg'>View In Cart</p>")
        curr.off()

  bookShowing: ->
    $('.next').click ->
      $('.slider-1').hide('slide', { direction: 'left'}, 10, ->
        $('.slider-2').show('slide', { direction: 'right'}, 10)
      )
    $('.prev').click ->
      $('.slider-2').hide('slide', { direction: 'right'}, 10, ->
        $('.slider-1').show('slide', { direction: 'left'}, 10)
      )

  cookieListings: ->
    $('#cart-button').off().on 'click', (e) ->
      $('.error-msg').remove()
      sendajaxReq()
      $('#book-showing').modal('toggle')

  sendajaxReq = ->
    if !checkCookie()
      ids = $.cookie('listing_ids').split(",")
      $.ajax
        type: "GET"
        url: '/cookielistings'
        data: {ids: ids}

  checkTime: ->
    $('input:radio[name="date"]').change ->
      val = Date.parse($(this).val())
      date = new Date()
      date.setHours(0,0,0,0)
      date = Date.parse(date)
      all=$('input:radio[name="time"]')
      setDisabled(all, false)
      first = $('#time_1')
      second = $('#time_2')
      third = $('#time_3')
      if val == date
        d = new Date()
        hour = d.getHours()
        $('input[name="time"]').prop("checked",false)
        if (hour>=10 && hour<12)
          setDisabled(first, true)
        else if (hour>=12 && hour<14)
          setDisabled(first, true)
          setDisabled(second, true)
        else if (hour>=14)
          setDisabled(all, true)
  
  setDisabled = (element, val) ->
    element.prop("disabled", val)

  displayTime: ->
    $('input[name="time"],input[name="date"]').change ->
      timeFunction()
      
  timeFunction = ->
    day = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]
    slot = ["10AM - 12PM","12PM - 2PM","2PM - 5PM"]
    booking_time = $('input[name="time"]:checked')
    booking_date = $('input[name="date"]:checked')
    if(booking_date.length && booking_time.length)
      date = $('input[name="date"]:checked').val()
      time = $('input[name="time"]:checked').val()
      d= new Date(date)
      if $('.time p.msg').length
        $('.time p:last').replaceWith('<p class="msg">'+day[d.getDay()]+' '+(d.getMonth()+1)+'/'+d.getDate()+' between '+slot[time-1]+'</p>')
      else
        if time
          $('.time .col-sm-8').append('<p class="msg">'+day[d.getDay()]+' '+(d.getMonth()+1)+'/'+d.getDate()+' between '+slot[time-1]+'</p>')
    else
      $('.time p.msg').remove()

  errorCheck: (event)->
    $('input[type="submit"]').click ->
      $('#showing_form').submit (event) ->
        $('.error-msg').remove()
        if errorMessages()
          event.preventDefault()
 
  errorMessages= ->
    flag =false
    time = $('input[name="time"]:checked').length
    date = $('input[name="date"]:checked').length
    if(!time || !date)
      $('.error-field').append('<p class="error-msg">*Please select a date and time</p>')
      flag = true
    if checkCookie()
      $('.error-field').append('<p class="error-msg">*Please select an apartment before you submit</p>')
      flag = true
    return flag

  removeApt: ->
    $('.appointment').on 'click', 'a#btn1', (e)->
      id = String($(this).data('id'))
      arr = $.cookie('listing_ids').split(",")
      index = arr.indexOf(id)
      arr.splice(index, 1)
      $.cookie('listing_ids',arr)
      if checkCookie()
        $(this).parent().remove()
      else
        sendajaxReq()
      abc = new Rentaldeals()
      abc.cartItems()
      btn = $('.add-to-cart[data-id='+id+']')
      btn.removeClass("transform-button")
      btn.removeAttr("style")
      btn.parent().find('.cart-msg').hide()
      $(this).off(e)

  viewCart: ->
    $('body').off().on 'click', 'p.cart-msg', ->
      sendajaxReq()
      $('#book-showing').modal('show')

  modalShow: ->
    $('#book-showing').on 'shown.bs.modal', (e)->
      timeFunction()

  fancyBox: ->
    $('a.fancybox').fancybox()

  @setup: ->
    new Rentaldeals

App.Rentaldeals = Rentaldeals.setup
