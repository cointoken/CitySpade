class RoomForm
  constructor: ->
    @petLogic()
    @datePicker()
    @petChecklist()

  petChecklist: =>
    $('#No').change( =>
      @petLogic()
    )

  petLogic: ->
    if( $('#No').prop("checked") == true )
      # Uncheck
      $('#Dog').prop("checked", false)
      $('#Cat').prop("checked", false)
      # Disable
      $('#Dog').prop("disabled", true)
      $('#Cat').prop("disabled", true)
      # strikethrough
      $('#Dog').parent().addClass("disabled-pet")
      $('#Cat').parent().addClass("disabled-pet")
    else
      $('#Dog').prop("disabled", false)
      $('#Cat').prop("disabled", false)
      $('#Dog').parent().removeClass("disabled-pet")
      $('#Cat').parent().removeClass("disabled-pet")

  datePicker: ->
    $('#roomStartDate').pickadate({
      min: new Date(Date.today)
    })
    $('#roomEndDate').pickadate({
      min: new Date(Date.today)
    })

  @setup: ->
    new RoomForm

class RoomIndex
  constructor: ->
    @tooltipInit()

  tooltipInit: ->
    # Bootstrap Tooltip
    $('[data-toggle="tooltip"]').tooltip()

  @setup: ->
    new RoomIndex

App.RoomFormSetup = RoomForm.setup
App.RoomIndex = RoomIndex.setup
