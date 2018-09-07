class RoommateForm
  constructor: ->
    @petLogic()
    @petChecklist()
    @datePicker()

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
    $('#roommateMoveDate').pickadate({
      min: new Date(Date.today)
    })

  @setup: ->
    new RoommateForm

App.RoommateFormSetup = RoommateForm.setup
