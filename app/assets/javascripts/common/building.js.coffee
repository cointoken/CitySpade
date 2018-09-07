class BuildingPage
  constructor: ->
    @showImages()
    @fancyCarousel()
    @fancypopup()
    @scrollSidebar()
    @validateAvailability()
    @changeTabs()

  showImages: ->
    $('.show-more span').click ->
      $('.img-row:not(:first)').slideToggle("slow")
      txt = $(this).text()
      if txt == "Show more"
        $(this).text("Show less")
      else
        $(this).text("Show more")

  
  fancyCarousel: ->
    $('.nav-pills li').first().addClass('active')
    $('.floorplans').first().addClass('in active')
    $('.item').first().addClass('active')
    $(".img-fancy").fancybox
      btnTpl:
        arrowLeft:
          '<a data-fancybox-prev class="fancybox-button fancybox-button--arrow_left bttn-left" title="{{PREV}}" href="javascript:;">' +
          '<i class="fa fa-arrow-circle-left fa-3x"></i>'+'</a>'
        arrowRight:
          '<a data-fancybox-next class="fancybox-button fancybox-button--arrow_right bttn-right" title="{{NEXT}}" href="javascript:;">' +
          '<i class="fa fa-arrow-circle-right fa-3x"></i>'+'</a>'

  fancypopup: ->
    $('.fplan').fancybox
      autoScale: true,
      type: 'iframe'

  scrollSidebar: ->
    $(window).scroll (e) ->
      pos = $('.availability').offset().top
      if ($(window).scrollTop() > $('.building-cover').height()) && ($('.availability').offset().top + $('.availability').height() < $('#sp-footer-wrapper').offset().top)
        $('.availability').css
          position: 'fixed'
          top: '100px'
      if $(window).scrollTop() <= $('.building-cover').height()
        $('.availability').css
          position: 'absolute'
          top: '100px'
      if ($('.availability').offset().top + $('.availability').height() + 80) > $('#sp-footer-wrapper').offset().top
        $('.availability').css
          position: 'absolute'
          top: $('#map').offset().top - $('.availability').height() + 'px'


  validateAvailability: ->
    $('#sendMsg').click (e) ->
      form = $('#modalMessage')
      form.validate({
        rules:
          'fname':
            required: true
          'lname':
            required: true
          'email':
            required: true
            email: true
          'message':
            required: true
      })

  changeTabs: ->
    $('#tab_selector').on 'change', (e) ->
      $('.form-tabs li a').eq($(this).val()).tab('show')


  @setup: ->
    new BuildingPage

class BuildingList
  constructor: ->
    @mapScroll()
    @priceFilter()

  mapScroll: ->
    $(window).scroll ->
      if($('.col-map').offset().top + $('.col-map').height() + 186 >= $('#sp-footer-wrapper').offset().top-186)
        $('.col-map').css('position', 'absolute')
        $('.col-map').css('top', ($('.card-list').last().offset().top) + 'px')
      if $(document).scrollTop() < $('.col-map').offset().top
        $('.col-map').css('position', 'fixed')
        $('.col-map').css('top', '186px')

  priceFilter: ->
    $('#slider').slider
      range: true
      min: 0
      max: 10000
      step: 25
      values: [0, 10000]
      slide: (ev, ui) ->
        $('span.min').text(ui.values[0])
        $('span.max').text(ui.values[1])


    $('.price-filter').click ->
      style = $('.dropdown-price').css('display')
      if style == "block"
        $(this).removeClass("active")
      else
        $(this).addClass("active")
      $('.dropdown-price').css
        top: $('#building-list').offset().top + 'px'
      $('.dropdown-location').hide()
      $('.dropdown-price').toggle()
      $('.more-filter').removeClass("active")

    $('.more-filter').click ->
      style = $('.dropdown-location').css('display')
      if style == "block"
        $(this).removeClass("active")
      else
        $(this).addClass("active")
      
      $('.dropdown-location').css
        top: $('#building-list').offset().top + 'px'
      $('.dropdown-price').hide()
      $('.dropdown-location').toggle()
      $('.price-filter').removeClass("active")

    $('.btn-apply').click ->
      $('.dropdown-price, .dropdown-location').hide()
      $('.price-filter, .more-filter').removeClass("active")
      minimum = $('#slider').slider("values")[0]
      maximum = $('#slider').slider("values")[1]
      $('.price-filter').text('$'+minimum+' - $'+maximum)
      loc = $('input[name="location"]:checked').val()
      loc_txt = $('input[name="location"]:checked').parent().text()
      #id = $('input[name="school"]:checked').val()
      $('.more-filter').text(loc_txt)
      #$('.more-filter').text(id)
      $.ajax
        type: "GET"
        url: '/buildings'
        data:
          search:
            min: minimum
            max: maximum
          location: loc
          #school: id
        dataType: 'script'

    $('input[name="location"]').on 'change', ->
      $('input[name="school"]').attr('checked', false)
      $('.sch-label').removeClass("active")
    
    $('input[name="school"]').on 'change', ->
      $('input[name="location"]').attr('checked', false)
      $('.loc-label').removeClass("active")

  @setup: ->
    new BuildingList

App.BuildingPage = BuildingPage.setup
App.BuildingList = BuildingList.setup
