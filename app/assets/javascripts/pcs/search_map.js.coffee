App.SearchMap =
  init: ->
    this.AutoLocation()
    this.SearchFormInit()
    this.zoomInAndOut()
  AutoLocation: ->
    $('.any-neighborhood-input').autocomplete(
      serviceUrl: '/api/places/any_neighborhoods'
      dataType: 'json'
      minChars: 2
      lookupFilter: (suggestion, originalQuery, queryLowerCase)->
        re = new RegExp('\\b' + $.Autocomplete.utils.escapeRegExChars(queryLowerCase), 'gi')
        return re.test(suggestion.value)
      formatResult: (suggestion, value)->
        pattern = '(' + $.Autocomplete.utils.escapeRegExChars(value) + ')'
        old_result = suggestion.value.replace(new RegExp(pattern, 'gi'), '<strong>$1<\/strong>')
        return old_result
      onSelect: (suggestion) ->
        params = {}
        params.ne_lat = suggestion.ne_lat
        params.ne_lng = suggestion.ne_lng
        params.sw_lat = suggestion.sw_lat
        params.sw_lng = suggestion.sw_lng
        params.lat = suggestion.lat
        params.lng = suggestion.lng
        params.location = suggestion.name
        if typeof map != 'undefined'
          map.setCenter(new google.maps.LatLng(params.lat, params.lng))
          map.setZoom(16)
        resetUrl(params)
        $.get '/api/places/coordinates?area_id=' + suggestion.id, (data)->
          Maps.DrawPolygon(data.coordinates[0])
    )
  ChangeUrl: ->
    params = $('#search-map-form input').serialize()
    params = QueryString(params)
    delete params['commit']
    params.price_from ||= null
    params.price_to ||= null
    params.beds ||= null
    params.title ||= null
    resetUrl(params)
  SearchFormInit: ->
    $('#search-map-form input').bind 'keypress', (event)->
      code = event.keyCode || event.which
      if(code == 13)
        App.SearchMap.ChangeUrl()
    $('#search-map-form input[type="submit"]').bind 'click', (e) ->
      App.SearchMap.ChangeUrl()
    $('#search-map-form .for-search-flag div').bind 'click', (e) ->
      self = $(this)
      if self.hasClass('selected')
        return
      self.parent().find('div').removeClass('selected')
      self.addClass('selected')
      url = self.data('url') + '?'
      resetUrl(url, {})
      console.log url
    $('#filter-input-beds span').bind 'click', (e) ->
      self = $(this)
      if self.hasClass('selected')
        self.removeClass('selected')
      else
        self.addClass('selected')
      vals = ''
      $('#filter-input-beds span.selected').each (i, span) ->
        vals += ',' + $(span).data('bed')
      $('#filter-input-beds input').val(vals.substring(1))

    $('#filter-input-baths span').bind 'click', (e) ->
      self = $(this)
      if self.hasClass('selected')
        self.removeClass('selected')
      else
        self.addClass('selected')
      vals = ''
      $('#filter-input-baths span.selected').each (i, span) ->
        vals += ',' + $(span).data('bath')
      $('#filter-input-baths input').val(vals.substring(1))
    $(".search-map-form-bar a").bind 'click', (event)->
      $("#search-map-form").toggle('slideUp')
      if $(this).text() == "-"
        $(this).text("+").attr("title", "show")
      else
        $(this).text("-").attr("title", "hide")
  zoomInAndOut: () ->
    $('#zoom-btns .zoom-in').bind 'click', (e)->
      zoom = map.getZoom()
      zoom += 1
      map.setZoom(zoom)
    $('#zoom-btns .zoom-out').bind 'click', (e)->
      zoom = map.getZoom()
      zoom -= 1
      map.setZoom(zoom)
