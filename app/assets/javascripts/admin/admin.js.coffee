#= require best_in_place
#= require best_in_place.jquery-ui

class AdminSection
  constructor: ->
    @contactEmails()
    @autoComplete()
    @addBuildingImage()
    @addFloorplan()
    @addTags()

  #Best in place initialization
  contactEmails: ->
    $('.best_in_place').best_in_place()

  #Autocomplete declaration using Selectize.js
  autoComplete: ->
    $('.email-select').selectize
      valueField: 'email'
      labelField: 'email'
      searchField: ['email', 'building']
      maxItems: null
      create: false
      plugins: ['remove_button']
      placeholder: 'To: '
      highlight: false
      render:
        option: (item, escape) ->
          return '<div class="option">'+ (if item.email then '<p class="head">'+escape(item.email)+'</p>' else '')+(if item.building then '<span class="sub">'+escape(item.building)+'</span>' else '')+(if item.name then '<span class="sub">'+' , '+escape(item.name)+'</span>' else '')+'</div>'
      load: (query, callback) ->
        if !query.length
          return callback()
        $.ajax
          url: '/admin/autocomplete'
          contentType: "application/json; charset=utf-8"
          dataType: 'json'
          data:
            query: query #request.term
          error: ->
            callback()
          success: (res) ->
            callback(res)

  addBuildingImage: ->
    $('#new_building_image').fileupload
      dataType: "script"
      progressall: (e,data) ->
        progress = parseInt(data.loaded / data.total * 100, 10)
        $('#progress .bar').css('width', progress + '%')

  addFloorplan: ->
    $('#new_floorplan').fileupload
      dataType: "script"
      replaceFileInput: false
      add: (e,data) ->
        data.context = $('<button/>').addClass('floor-submit').text('Upload').appendTo('.new-form').click ->
          data.context = $('<p/>').text('Uploading...').replaceAll($(this))
          data.submit()
        #$('.floor-submit').click ->
        #  $('.floor-submit').append("<i class='fa fa-spinner fa-spin fa-2x'></i>")
        #  data.submit()
      done:(e,data) ->
        data.context.text('Upload finished.')
        #$('.fa-spinner').remove()
        $('#new_floorplan')[0].reset()

  addTags: ->
    $('.sepcial_offers_field').on('change keydown paste input', (e) ->
      txt = $(e.target).val()
      offers_arr = txt.split(/[,|，]/)
      tags = []
      $('.offers_tags .tag').each (i, tag) ->
        $(tags).append($(tag).val())

      $('.offers_tags .tag').each (i, tag) ->
        if tag not in offers_arr
          $(tag).remove()

      for offer in offers_arr
        if offer not in tags
          $('.offers_tags').append("<span class='tag' style='border: 1px solid #fff; border-radius: 5px; padding: 5px 10px; margin-right: 10px; background: #29bcb8; color: #fff;'>"+offer+"</span>")

    )


  @setup: ->
    new AdminSection

App.AdminSection = AdminSection.setup
