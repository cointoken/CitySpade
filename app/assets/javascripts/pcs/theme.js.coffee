# = require menu
window.Theme =
  init: ->
    $('.sp-menu').spmenu({ startLevel: 0, direction: 'ltr', initOffset: {x: 0,y: 0},subOffset: {x: 0,y: 0},center: 0,mainWidthFrom: 'body',type: 'mega'})
    $('#sp-main-menu > ul').mobileMenu({defaultText:'--Navigate to--',appendTo: '#sp-mobile-menu'})
