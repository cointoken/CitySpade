window.MbSearch = MbSearch =
  Init: ->
    MbSearch.AutoComplete()
    # MbSearch.ChooseUrl()
    MbSearch.MultiSelect()
    MbSearch.CurrentCity()
    MbSearch.DoLike()
    # MbSearch.InitUpdateCity()
    MbSearch.FilterSearch()
    MbSearch.BackToSearchResults()
    MbSearch.SelectUpdateCity()
    MbSearch.showBanner()
    @NearBy()
  AutoComplete: ->
    $('.autocomplete-input').autocomplete(
      serviceUrl: '/search/autocomplete'
      dataType: 'json'
      minChars: 2
      lookupFilter: (suggestion, originalQuery, queryLowerCase)->
        re = new RegExp('\\b' + $.Autocomplete.utils.escapeRegExChars(queryLowerCase), 'gi')
        return re.test(suggestion.value)
      formatResult: (suggestion, value) ->
        pattern = '(' + $.Autocomplete.utils.escapeRegExChars(value) + ')'
        parent  = "<span class='autocomplete-parent'>" + suggestion.parent + "</span>"
        old_result = suggestion.value.replace(new RegExp(pattern, 'gi'), '<strong>$1<\/strong>')
        return (old_result + parent)
      onSelect: (suggestion) ->
        $("input#location").val(suggestion.parent)
    )

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
      width: '100%'
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
      width: '100%'
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
    $(".select-area.multiple-select").multipleSelect(
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
        form = $('#mb-banner-search form')
        href = form.attr('action')
        urls = href.split('/')
        if urls[2].match('index') || urls[2].match('for')
          tmp = urls.pop()
          urls.push view.value
          urls.push tmp
        else
          urls[2] = view.value
        form.attr 'action', urls.join('/')
        $('.autocomplete-input').autocomplete 'clearCache'
    )

  #ChooseUrl: ->
  #$(".listing-flag input[type='radio']").click ->
  #url = $(this).data('url')
  #form = $("#mb-banner-search form")
  #full_url = form.attr('action')
  #full_urls = full_url.split('/').pop()
  #full_urls.push url
  #form.attr('action', full_urls.join('/'))

  CurrentCity: ->
    current_city = $("#new_listing").attr("action")
    if current_city
      current_city = current_city.match(/philadelphia/)
    $(".half").removeClass("half-active")
    if current_city
      $(".half-right").addClass("half-active")
    else
      $(".half-left").addClass("half-active")
  DoLike: ->
    $('a.collect,a.uncollect').click ->
      if !gon.logined
        window.location.href = $(this).attr('href')
        return false
    $('a.collect,a.uncollect').bind 'ajax:success', (e,data)->
      self = $(this)
      i = self.find('.collect-num')
      i.html(data.collect_num)
      #heart_num = self.find('.fa-heart')
      #if heart_num.html() != ''
      #heart_num.html(data.collect_num)
      url = self.attr('href')
      self.attr('href', self.attr('data-reverse-url'))
      self.attr('data-reverse-url', url)
      if self.attr('class').indexOf('uncollect') > -1
        self.removeClass('uncollect')
        self.addClass('collect')
        i.removeClass('collected')
        i.addClass('uncollected')
      else
        self.removeClass('collect')
        self.addClass('uncollect')
        i.removeClass('uncollected')
        i.addClass('collected')

  #====================
  # update search
  #====================
  FilterSearch: ->
    # 利用高度和absolute实现滑行效果
    $(".filter-btn a").click ->
      MbSearch.FilterShow()
  FilterShow: ->
    nowHeight = $(".update-container").height()
    oriHeight = $(".search-container").height()
    $(".search-container").animate({left: "-100%"})
    $(".search-container").data("height", oriHeight)
    $(".search-container").css("height", nowHeight).css("overflow", "hidden")
    $(".update-container").animate({left: "0px"})

  BackToSearchResults: ->
    $("#mb-banner-search .back a").click ->
      oriHeight = $(".search-container").data("height")
      $(".search-container").animate(left: "0px")
      $(".search-container").css("height", oriHeight).css("overflow", "visible")
      $(".update-container").animate(left: "-100%")

  SelectUpdateCity: ->
    $(".update-city-row .city-btn").click ->
      area = $(this).data('area')
      action = $("#new_listing").attr('action').replace(/\/search\/(.+)\//, "/search/" + area + '/')
      $("#new_listing").attr('action', action)
      $(".update-city-row .city-btn").removeClass('update-active')
      $(this).addClass('update-active')
      $.get('/search/set_current_area', { current_area: area })
      $('.autocomplete-input').autocomplete 'clearCache'

  showBanner: ->
    noFee = $("#banner-noFee")
    reviewSearch = $("#mb-home-reviews-input")
    bannerInput = $("#mb-banner-input")
    listingSearch = $("#mb-home-listings-input")
    listing_flag = $(".listing-flag input[type='radio']")
    $('.for-search-review #mb-home-listings-input input').prop('disabled', true)
    $('.for-search-listing #mb-home-reviews-input input').prop('disabled', true)
    listing_flag.click ->
      selected = $('input:radio:checked').val()
      form = $("#mb-banner-search form")
      url = $(this).data('url')
      if selected == 'reviews'
        listingSearch.hide().find('input').prop('disabled', true)# = $("#home-listings-input").hide()
        reviewSearch.show().find('input').prop('disabled', false)#attr("style","display:block")
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
          noFee.attr("style","display:block")
        else
          noFee.attr("style","display:none")
        reviewSearch.hide().find('input').prop('disabled', true)#attr("style","display:block")
        listingSearch.show().find('input').prop('disabled', false)# = $("#home-listings-input").hide()
  NearBy: ->
   $(".nearby-search a").click ->
     url = $(this).data('url')
     callback = (pos)->
       window.location.href = url + '?lat=' + pos.coords.latitude + '&lng=' + pos.coords.longitude
     error = (error)->
       console.log error
       window.location.href = url
     App.GetGeoLocation callback, error
