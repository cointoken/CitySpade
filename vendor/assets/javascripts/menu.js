(function ($) {
  $.fn.spmenu = function (o) {
    var p = {
      startLevel: 0,
      direction: 'ltr',
      center: 0,
      marginLeft: 0,
      marginTop: 0,
      type: 'mega',
      mainWidthFrom: '.container',
      initOffset: {
        x: 0,
        y: 0
      },
      subOffset: {
        x: 0,
        y: 0
      }
    };
    var o = $.extend(p, o);
    return $(this).each(function () {
      $(this).find('>li.menu-item.parent').each(function (e) {
        var f = $(this);
        var g = f.find('>.sp-submenu');
        g.attr('style', '');
        var h = (f.closest('ul.sp-menu').hasClass('level-' + o.startLevel) ? true : false);
        if (h) {
          g.addClass('sub-level');
          var i = f.height() + o.marginTop;
          var j = o.marginLeft;
          if (o.center) {
            j = -(g.width() / 2) + (g.closest('.parent').width() / 2)
          } else {
            var k = g.offset();
            var l = $(o.mainWidthFrom).width();
            if (l < n) {
              var m = n - l
            } else {
              var m = 0
            }
            j = j - m
          }
          g.find('>.sp-submenu-wrap').css({
            'margin-top': o.initOffset.y,
            'margin-left': o.initOffset.x
          });
        } else {
          g.addClass('sub-level-child');
          var i = o.marginTop;
          var j = f.children('.sp-submenu').parent().width();
          var k = g.offset();
          var n = k.left + g.width();
          var l = $(o.mainWidthFrom).width();
          if (l > $(window).width()) {
            l = $(window).width()
          }
          if (o.mainWidthFrom == 'body') l = l - (g.width() / 2);
          if (l < n) {
            j = -(g.width())
          }
          g.find('>.sp-submenu-wrap').css({
            'margin-top': o.subOffset.y,
            'margin-left': o.subOffset.x
          });
        }
        f.hover(function (a) {
          a.stopImmediatePropagation();
          $(this).find('>.sp-submenu').removeClass('open');
          var b = $(this).find('>.sp-submenu');
          if (f.parent().hasClass('level-0')) {
            var e = f.height();
            if ((f.offset().top - $(window).scrollTop()) > $(window).height() / 2) {
              e = 0 - b.height()
            }
            if (o.direction == 'rtl') {
              if (f.offset().left + f.width() < b.width()) {
                b.css({
                  top: e,
                  right: (0 - (b.width() - f.offset().left) + f.width()) + 'px'
                }).addClass('open')
              } else {
                b.css({
                  top: e,
                  right: 0
                }).addClass('open')
              }
              return
            }
            if ((f.offset().left + b.width()) > $(window).width()) {
              b.css({
                top: e,
                left: $(window).width() - (f.offset().left + b.width()) + 'px'
              }).addClass('open')
            } else {
              b.css({
                top: e,
                left: 0
              }).addClass('open')
            }
            return true
          }
          if (o.type == 'split' && f.parent().hasClass('level-1')) {
            b.css({
              top: f.height(),
              left: 0
            }).addClass('open');
            return
          }
          var c = $(window).width();
          if (o.direction == 'rtl') {
            if (f.offset().left < b.width()) {
              var d = 0 - b.width();
              b.css({
                right: d
              })
            } else {
              var d = f.width();
              b.css({
                right: d
              })
            }
            b.addClass('open');
            return true
          }
          if (f.offset().left + f.width() + b.width() > c) {
            var d = 0 - b.width();
            b.css({
              left: d
            });
          } else {
            var d = f.width();
            b.css({
              left: d
            });
          }
          b.addClass('open')
        }, function (a) {
          $(this).find('>.sp-submenu').removeClass('open')
        });
      });
    });
  }
  $.fn.spmenudrop = function (p) {
    var q = {
      startLevel: 0,
      direction: 'ltr',
      center: 0,
      marginLeft: 0,
      marginTop: 0,
      mainWidthFrom: '.container',
      initOffset: {
        x: 0,
        y: 0
      },
      subOffset: {
        x: 0,
        y: 0
      }
    };
    var p = $.extend(q, p);
    var r = $('ul.sp-menu.level-0 > li.active');
    var s = $('ul.sp-menu.level-0').find('li.parent').index(r);
    if (s != -1) $('#sublevel ul.level-1').not('.empty').eq(s).css({
      display: 'block'
    });
    $('ul.level-0 > li').not('.parent').hover(function () {
      clearInterval(p.Interval);
      $('#sublevel ul.level-1').css({
        display: 'none'
      })
    }, function () {
      p.Interval = setInterval(function () {
        $('#sublevel ul.level-1').css({
          display: 'none'
        });
        var a = $('ul.sp-menu.level-0 > li.active');
        var b = $('ul.sp-menu.level-0').find('li.parent').index(a);
        if (b != -1) $('#sublevel ul.level-1').not('.empty').eq(b).css({
          display: 'block'
        })
      }, 1000)
    });
    $('#sublevel, ul.level-0 li.parent').hover(function (a) {
      clearInterval(p.Interval)
    }, function () {
      p.Interval = setInterval(function () {
        $('#sublevel ul.level-1').css({
          display: 'none'
        });
        var a = $('ul.sp-menu.level-0 > li.active');
        var b = $('ul.sp-menu.level-0').find('li.parent').index(a);
        if (b != -1) $('#sublevel ul.level-1').not('.empty').eq(b).css({
          display: 'block'
        })
      }, 1000)
    });
    return $(this).each(function () {
      $(this).find('>li.menu-item.parent').each(function (f) {
        var g = $(this);
        var h = g.find('>.sp-submenu');
        h.attr('style', '');
        var i = (g.closest('ul.sp-menu').hasClass('level-' + p.startLevel) ? true : false);
        if (i) {
          h.addClass('sub-level');
          var j = g.height() + p.marginTop;
          var k = p.marginLeft;
          if (p.center) {
            k = -(h.width() / 2) + (h.closest('.parent').width() / 2)
          } else {
            var l = h.offset();
            var m = $(p.mainWidthFrom).width();
            if (m < o) {
              var n = o - m
            } else {
              var n = 0
            }
            k = k - n
          }
          h.find('>.sp-submenu-wrap').css({
            'margin-top': p.initOffset.y,
            'margin-left': p.initOffset.x
          })
        } else {
          h.addClass('sub-level-child');
          var j = p.marginTop;
          var k = g.children('.sp-submenu').parent().width();
          if (g.parent().hasClass('level-1')) {
            j = 37
          } else {
            k = g.parents('.sp-submenu-inner').width() - 45
          }
          var l = h.offset();
          var o = l.left + h.width();
          var o = h.parent().offset().left + h.parent().width() + h.width();
          var m = $(p.mainWidthFrom).width();
          h.find('>.sp-submenu-wrap').css({
            'margin-top': p.subOffset.y,
            'margin-left': p.subOffset.x
          })
        }
        g.hover(function (a) {
          $(this).find('>.sp-submenu').removeClass('open');
          var b = $(this).find('>.sp-submenu');
          if (g.parent().hasClass('level-0')) {
            var c = g.parent().find('li.parent').index(g);
            $('#sublevel ul.level-1').css({
              display: 'none'
            });
            $('#sublevel ul.level-1').not('.empty').eq(c).css({
              display: 'block'
            });
            return true
          }
          if (g.parent().hasClass('level-1')) {
            b.css({
              top: g.height(),
              left: 0
            }).addClass('open');
            return true
          }
          var d = $(window).width();
          if (p.direction == 'rtl') {
            if (g.offset().left < b.width()) {
              var e = 0 - b.width();
              b.css({
                right: e
              })
            } else {
              var e = b.width() - 20;
              b.css({
                right: e
              })
            }
            b.addClass('open');
            return true
          }
          if (g.offset().left + g.width() + b.width() > d) {
            var e = 0 - b.width();
            b.css({
              left: e
            })
          } else {
            var e = b.width() - 20;
            b.css({
              left: e
            })
          }
          b.addClass('open')
        }, function (a) {
          $(this).find('>.sp-submenu').removeClass('open')
        })
      })
    })
  }

  $.fn.mobileMenu = function (b) {
    var c = {
      defaultText: 'Navigate to...',
      className: 'select-menu',
      subMenuClass: 'menu-item',
      subMenuDash: '-',
      appendTo: '#sp-mmenu'
    }, settings = $.extend(c, b),
      el = $(this);
    mobileMenu = $(settings.appendTo);
    this.each(function () {
      el.find('ul').addClass(settings.subMenuClass);
      $('<select />', {
        'class': settings.className
      }).appendTo(mobileMenu);
      $('<option />', {
        "value": '#',
        "text": settings.defaultText
      }).appendTo('.' + settings.className);
      el.find('a').each(function () {
        var a = $(this),
          optText = '&nbsp;' + a.find('span.menu-title').text(),
          optSub = a.parents('.' + settings.subMenuClass),
          len = optSub.length,
          dash;
        if (a.parents('ul').hasClass(settings.subMenuClass)) {
          dash = Array(len + 1).join(settings.subMenuDash);
          optText = dash + optText
        }
        $('<option />', {
          "value": this.href,
          "html": optText,
          "selected": (this.href == window.location.href)
        }).appendTo('.' + settings.className)
      });
      $('.' + settings.className).change(function () {
        var a = $(this).val();
        if (a !== '#') {
          window.location.href = $(this).val()
        }
      })
    });
    return this
  }
})(jQuery);