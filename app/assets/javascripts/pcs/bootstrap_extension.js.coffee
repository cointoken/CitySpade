App.BootstrapExtension =
  init: ->
    this.showFullyGoogleMap()

  showFullyGoogleMap: ->
    $('a[href="#google-map"]').on 'shown.bs.tab', ->
      Maps.listingShow()
    $('a[href="#google-street-view"]').on 'shown.bs.tab', ->
      Maps.streetViewShow()
    $("a.map-tab[href='#review-map-pane']").on 'shown', ->
      Maps.reviewShow()
    $("a.map-tab[href='#review-street-view-pane']").on 'shown', ->
      Maps.StreetView(gon.local,'pano')
