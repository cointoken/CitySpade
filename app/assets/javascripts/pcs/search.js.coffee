App.Search =
  init: ->
    this.MultiSelect()
    this.initMultSelectSearch()
    #this.AutoComplete()
    #this.ChooseUrl()
    #this.AutoComplete()
    #  this.ChooseUrl()
    this.SetCurrentArea()
    this.SwitchMap()
    this.showBanner()
    this.initNoFee()
    this.datetimePicker()
  AutoComplete: ->
    ## reset input
    origin_title = $("#listing_title").val()
    reset_flag = false
    reset_flag = true if origin_title && origin_title.length > 0
    reset_input = ->
      if reset_flag && origin_title != $("#listing_title").val()
        $('#banner-input .multiple-select').multipleSelect("uncheckAll")
        $('#banner-input input[name^="price"]').val('')
        $("#banner-listing-noFee").attr('checked', false)
        $("#listing_title").unbind('keypress', reset_input)
        reset_flag = false
    #$('.autocomplete-input').autocomplete(
      #serviceUrl: '/search/autocomplete'
      #dataType: 'json'
      #minChars: 2
      #lookupFilter: (suggestion, originalQuery, queryLowerCase)->
        #re = new RegExp('\\b' + $.Autocomplete.utils.escapeRegExChars(queryLowerCase), 'gi')
        #return re.test(suggestion.value)
      #formatResult: (suggestion, value) ->
        #$(".autocomplete-input").append($("<option value=\"#{suggestion.name}\">#{suggestion.name}</option>"))
        #pattern = '(' + $.Autocomplete.utils.escapeRegExChars(value) + ')'
        #parent  = "<div class='autocomplete-parent'>" + suggestion.parent + "</div>"
        #old_result = suggestion.value.replace(new RegExp(pattern, 'gi'), '<strong>$1<\/strong>')
        #return (old_result + parent)
      #onSelect: (suggestion) ->
        #$("input#location").val(suggestion.parent)
        #if reset_flag && suggestion.name != origin_title
          #reset_input()
    #)
    if reset_flag
      $("#listing_title").bind('keypress', reset_input)

  MultiSelect: ->
    setSelectClick = (ul, view)->
      lis = $(ul).find('li')
      for li in lis
        li = $(li)
        label = li.find('label').text()
        if label == view.label
          if view.checked
            li.addClass('ms-li-selected')
          else
            li.removeClass('ms-li-selected')
    onCheckAll = (ul)->
      lis = $(ul).find('li')
      for li in lis
        li = $(li)
        li.addClass('ms-li-selected')
    onUncheckAll = (ul)->
      lis = $(ul).find('li')
      for li in lis
        li = $(li)
        li.removeClass('ms-li-selected')
    AnySelected = (ul) ->
      li = $(ul).find('li').first()
      if li.hasClass('ms-li-selected') && li.text().match('Any')
        return true
      else
        return false
    onOpen = (ul, org)->
      val = $(org).val()
      if val
        lis = $(ul).find('li')
        for li in lis
          li = $ li
          v = li.find('input').val()
          if v && val.indexOf(v.toString()) > -1
            li.addClass('ms-li-selected')
    firstOpen = {beds: true, baths: true}
    $('#listing_beds.multiple-select').multipleSelect(
      width: 220
      selectAll: false
      placeholder: 'Any Beds'
      position: 'bottom beds'
      onOpen: ->
        if firstOpen.beds
          onOpen('.ms-drop.beds', '#listing_beds')
          firstOpen.beds = false
      onClick: (view) ->
        if view.label.match('Any')
          $('#listing_beds.multiple-select').multipleSelect("uncheckAll")
          if view.checked
            $('#listing_beds.multiple-select').multipleSelect("setSelects", [''])
        else
          if AnySelected('.ms-drop.beds')
            $('#listing_beds.multiple-select').multipleSelect("uncheckAll")
            if view.checked
              $('#listing_beds.multiple-select').multipleSelect("setSelects", [view.value])
        setSelectClick(".ms-drop.beds", view)
      onCheckAll: ->
        onCheckAll('.ms-drop.beds')
      onUncheckAll: ->
        onUncheckAll('.ms-drop.beds')
    )
    $('#listing_baths.multiple-select').multipleSelect(
      width: 220
      position: 'right baths'
      placeholder: 'Any Baths'
      selectAll: false
      onOpen: ->
        if firstOpen.baths
          onOpen('.ms-drop.baths', '#listing_baths')
          firstOpen.baths = false
      onClick: (view) ->
        if view.label.match('Any')
          $('#listing_baths.multiple-select').multipleSelect("uncheckAll")
          if view.checked
            $('#listing_baths.multiple-select').multipleSelect("setSelects", [''])
        else
          if AnySelected('.ms-drop.baths')
            $('#listing_baths.multiple-select').multipleSelect("uncheckAll")
            if view.checked
              $('#listing_baths.multiple-select').multipleSelect("setSelects", [view.value])
        setSelectClick(".ms-drop.baths", view)
      onCheckAll: ->
        onCheckAll('.ms-drop.baths')
      onUncheckAll: ->
        onUncheckAll('.ms-drop.baths')
    )
    $('.multiple-select-for-single').multipleSelect(
      single: true
      onClick: (view) ->
        $.get('/search/set_current_area', { current_area: view.value })
        banner = $("#banner .home-banner-bg")
        city_title = view.label
        #console.log city_title
        #console.log city_title == 'New York'
        if city_title.trim() == 'New York'
          city_title = 'New Yorker'
        $("#city-title-name").html(city_title)
        if banner.length > 0
          current_area = banner.data('current_area')
          banner.data('current_area', view.value)
          banner.removeClass(current_area)
          banner.addClass(view.value)
        if window.location.pathname == '/'
          window.location.href = '/?current_area=' + view.value
        else
          href = window.location.href
          window.location.href = href.replace(/\/search\/.+\//, '/search/' + view.value + '/')
        form = $('#banner-search form')
        href = form.attr('action')
        urls = href.split('/')
        if urls[2].match('index') || urls[2].match('for')
          tmp = urls.pop()
          urls.push view.value
          urls.push tmp
        else
          urls[2] = view.value
        form.attr 'action', urls.join('/')
    )

  #ChooseUrl: ->
  #$(".listing-flag input[type='radio']").click ->
  #url = $(this).data('url')
  #form = $("#banner-search form")
  #full_url = form.attr('action')
  #full_urls = full_url.split('/').pop()
  #full_urls.push url
  #form.attr('action', full_urls.join('/'))


  SetCurrentArea: ->
    $("#set-current-area a.current-area-link").click ->
      data = $(this).data()
      $("#set-current-area a.current-area-link").removeClass('active')
      $(this).addClass('active')
      form = $("#banner-search form")
      url = form.attr('action')
      url = data.targetUrl + url.split('/').reverse()[0]
      form.attr('action', url)
      areas = ['new-york', 'boston', 'philadelphia']#['']
      for area in areas
        if data.currentArea.toLowerCase().replace(' ', '-') == area
          $('.banner-bg.home-banner-bg').addClass(area)
        else
          $('.banner-bg.home-banner-bg').removeClass(area)
      $.get('search/set_current_area', {current_area: data.currentArea})
  SwitchMap: ->
    if gon.search_map
      $('footer#sp-footer-wrapper,section#sp-coppyright-wrapper').hide()

  showBanner: ->
    noFee = $("#banner-noFee")
    reviewSearch = $("#home-reviews-input")
    bannerInput = $("#banner-input")
    listingSearch = $("#home-listings-input")
    listing_flag = $(".listing-flag input[type='radio']")

    $('.for-search-review #home-listings-input input').prop('disabled', true)
    $('.for-search-listing #home-reviews-input input').prop('disabled', true)
    listing_flag.click ->
      selected = $('input:radio:checked').val()
      form = $("#banner-search form")
      url = $(this).data('url')
      if selected == 'reviews'
        reviewSearch.show().find('input').prop('disabled', false)#attr("style","display:block")
        listingSearch.hide().find('input').prop('disabled', true)# = $("#home-listings-input").hide()
        form.attr('action', url)
      else
        full_url = form.attr('action')
        if full_url.indexOf('reviews') > -1
          full_url = form.data('sl')
        full_urls = full_url.split('/')#
        full_urls.pop()
        full_urls.push url
        form.attr('action', full_urls.join('/'))
        if selected == "rental"
          noFee.attr("style","visibility: visible")
        else
          noFee.attr("style","visibility: hidden")
        reviewSearch.hide().find('input').prop('disabled', true)#attr("style","display:block")
        listingSearch.show().find('input').prop('disabled', false)# = $("#home-listings-input").hide()

  initNoFee: ->
    noFee = $("#banner-noFee")
    selected = $('input:radio:checked').val()
    if selected == "rental"
      noFee.attr("style", "visibility: visible")
      $('.listing-flag').attr("style", "margin-top: 0px")
    else
      $('.listing-flag').attr("style", "margin-top: 48.5px")
      noFee.attr("style","visibility: hidden")

  initMultSelectSearch: ->
    $(".autocomplete-input").chosen(
      input_name: 'listing_address'
      # current_input_value: current_input_value
      input_width: 280
      #   no_results_text: "Searching for"
    )
    current_input_value = ''
    if gon.search && gon.search.current_input_value
       $('input[name="listing_address"]').val gon.search.current_input_value
    $("#listing_title_chosen").addClass("input-class large chosen-container-active")
  # TODO: Improvement
  datetimePicker: ->
    $('#filter-date').datetimepicker(
      format: 'yyyy-mm-dd'
      minView: 2
      autoclose: true
      minDate: new Date()
      startDate: new Date()
      pickerPosition: 'bottom-left'
      todayBtn: true
    ).on 'changeDate', (e)->
      date = e.date.getFullYear() + '-' + (e.date.getMonth() + 1) + '-' + (e.date.getDate() )
      search = window.location.search.substr(1)
      n_query = []
      if search.length > 0
        searchs = search.split("&")
        for sh in searchs
          n_query.push sh if sh.indexOf('date') < 0
      n_query.push 'date=' + date
      search = n_query.join("&")
      window.location.href = window.location.pathname + '?' + search
  #  $('.input-group.date .input-group-addon').datetimepicker({
      #todayBtn: "linked",
      #clearBtn: true,
      #todayHighlight: true,
      #orientation: "bottom left",
      #autoclose: true
    #})
