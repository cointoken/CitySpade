window.MbReview = MbReview =
  init: ->
    # this.GetCurrentCity()
    this.CheckFacebookLogin()
    this.reviewShowShare()
    this.showReviewMoreInfo()
    this.Search()
    Maps.showMap()
    Maps.neighborhoodStreetView()

  GetCurrentCity: ->
    $.get '/api/geoip', (res) ->
      $(".current-city").val(res.name + ", " + res.state)
  CheckFacebookLogin: ->
    $(".review-facebook-box, .review-on-facebook-label").click ->
      logined = false
      $.get '/account/check_facebook_login', (data, e) ->
        logined = data.logined
        if !logined
          $("#login-facebook").modal()
          $(".review-facebook-box").attr('checked',false)
          return logined
        else
          return logined

  reviewShowShare: ->
    if gon.page_protected
      $('.review-type-select-tag').click ->
        $('.review-type-select-tag').removeClass('selected')
        self = $(this)
        val  = self.data('val')
        self.addClass('selected')
        $('#review_review_type').val(val)
        $('#new-review-location').html(tmpl_base.tmpl({review_type: parseInt(val)}))
        $("select[name='review[state]']").multipleSelect({single: true,filter: true,width: 138})
      reviewShowShare1 = $('#review-show-share1')
      reviewShowShare2 = $('#review-show-share2')
      reviewShowShare3 = $('#review-show-share3')
      tmpl_base = $('#tmpl-new-review-location')
      tmpl_comment = $('#tmpl-new-review-comment')
      $("#review-show-btn1").click ->
        reviewShowShare1.attr('style','display:none')
        $('#new-review-location').html(tmpl_base.tmpl({review_type: 0}))
        $("select[name='review[state]']").multipleSelect({single: true,filter: true,width: 138})
        reviewShowShare2.attr('style','display:block')
        reviewShowShare3.attr('style','display:none')
      $("#review-show-btn2").click ->
        ele = document.getElementById('review_address')
        if ele.validity && !ele.validity.valid
          ele.focus()
          return
        ele = document.getElementById('review_city')
        if ele.validity && !ele.validity.valid
          ele.focus()
          return
        reviewShowShare1.attr('style','display:none')
        reviewShowShare2.attr('style','display:none')
        type_id = parseInt($('#review_review_type').val())
        $('#new-review-comment').html(tmpl_comment.tmpl({review_type: type_id}))
        App.Review.AssessLevel()
        reviewShowShare3.attr('style','display:block')
        App.Review.calApartAttrComment()
        $("#review-comment").validate()
      $("#review-show-pre").click ->
        reviewShowShare1.attr('style','display:none')
        reviewShowShare2.attr('style','display:block')
        reviewShowShare3.attr('style','display:none')

  showReviewMoreInfo: ->
    $(".more a.more-info").bind "click", () ->
      details = $(this).parent().parent().find(".info-details")
      detailsDisplay = details.find(".short-details").css("display")
      if detailsDisplay == "block"
        details.find(".short-details").css("display", "none")
        details.find(".long-details").css("display", "block")
        $(this).find(".more-text").text("Less")
        $(this).find(".more-arrow.fa-caret-up").css("display", "block")
        $(this).find(".more-arrow.fa-caret-down").css("display", "none")
      else
        details.find(".short-details").css("display", "block")
        details.find(".long-details").css("display", "none")
        $(this).find(".more-text").text("More")
        $(this).find(".more-arrow.fa-caret-up").css("display", "none")
        $(this).find(".more-arrow.fa-caret-down").css("display", "block")
      false
  Search: ->
    $("input#location").keypress (e) ->
      if e.keyCode  == 13
        return false
    $("#address.review-autocomplete").autocomplete(
      serviceUrl: '/api/places/autocomplete'
      dataType: 'json'
      minChars: 3
      lookupFilter: (suggestion, originalQuery, queryLowerCase)->
        re = new RegExp('\\b' + $.Autocomplete.utils.escapeRegExChars(queryLowerCase), 'gi')
        return re.test(suggestion.value)
      formatResult: (suggestion, value) ->
        pattern = '(' + $.Autocomplete.utils.escapeRegExChars(value) + ')'
        parent  = "<span class='autocomplete-parent'>" + suggestion.parent + "</span><div class='clearfix'></div>"
        old_result = suggestion.value.replace(new RegExp(pattern, 'gi'), '<strong>$1<\/strong>')
        return (old_result + parent)
      onHint: (hint) ->
        # console.log hint
      onSelect: (suggestion) ->
        console.log suggestion
        if suggestion.parent
          $("input#location").val(suggestion.parent.trim())
    )
    $("input#location").autocomplete(
      serviceUrl: '/api/places/cities'
      dataType: 'json'
      minChars: 2
      lookupFilter: (suggestion, originalQuery, queryLowerCase)->
        re = new RegExp('\\b' + $.Autocomplete.utils.escapeRegExChars(queryLowerCase), 'gi')
        return re.test(suggestion.value)
      formatResult: (suggestion, value) ->
        pattern = '(' + $.Autocomplete.utils.escapeRegExChars(value) + ')'
        parent  = "<span class='autocomplete-parent'>" + suggestion.parent + "</span>"
        suggest_val = suggestion.value.split(',')[0]
        old_result = suggest_val.replace(new RegExp(pattern, 'gi'), '<strong>$1<\/strong>')
        return (old_result + parent)
      onSelect: (suggestion) ->
        $.post('/api/places/set_city', {id: suggestion.id})
        return false
      onHint: (hint) ->
        # console.log hint
    )
