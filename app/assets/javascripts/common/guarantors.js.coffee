class Guarantor
  constructor: ->
    @showTooltip()

  showTooltip: ->
    tooltip_text="<div class='tooltip-top'><p>TheGuarantors can help you qualify for this apartment if you don't meet strict income, credit, or rental history requirements.</p></div><div class='tooltip-btm'><a href='/guarantors'>Learn more</a></div>"
    $('.guarantor-logo').tooltip
      title: tooltip_text,
      html: true,
      placement: 'bottom',
      delay: {show: 0, hide: 4000}

    $('.guarantor-logo-fbox').tooltip
      title: tooltip_text,
      html: true,
      placement: 'top',
      delay: {show: 0, hide: 4000}

  @setup: ->
    new Guarantor

App.Guarantor = Guarantor.setup
