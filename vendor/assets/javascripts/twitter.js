/**--------------------------------------------------------------------
# Package - JoomlaMan Module
# Version 1.0
# --------------------------------------------------------------------
# Author - JoomlaMan http://www.joomlaman.com
# Copyright (coffee) 2012 - 2013 JoomlaMan.com. All Rights Reserved.
# @license http://www.gnu.org/licenses/gpl-2.0.html GNU/GPLv2 or Later
# Websites: http://www.JoomlaMan.com
---------------------------------------------------------------------**/
 
;
(function($) {
  $.fn.twitterSearchesN = function(options) {
    if (typeof options == 'string')
      options = {
        term: options
      };
    return this.each(function() {
      var grabFlag = false,
      grabbing = false,
      $frame = $(this), text, $text, $title, $bird, $cont, height, paused = false,
      opts = $.extend(true, {}, $.fn.twitterSearchesN.defaults, options || {}, $.metadata ? $frame.metadata() : {});
				
      opts.formatter = opts.formatter || $.fn.twitterSearchesN.formatter; 
      opts.filter = opts.filter || $.fn.twitterSearchesN.filter;
			
      if (!opts.applyStyles) { // throw away all style defs
        for (var css in opts.css)
          opts.css[css] = {};
      }
				
      if (opts.bird) {
        $bird = $('<img class="twitterSearchesNBird" src="'+opts.birdSrc+'" />').appendTo($title).css(opts.css['bird']);
        if (opts.birdLink)
          $bird.wrap('<a href="'+ opts.birdLink +'"></a>');
      }
      $cont = $('<div class="twitterSearchesNContainter"></div>').appendTo($frame).css(opts.css['container']);
      cont = $cont[0];
			
      $frame.css(opts.css['frame']);
			
      height = $frame.innerHeight();
      $cont.height(height);
			
      if (opts.pause)
        $cont.hover(function(){
          paused = true;
        },function(){
          paused = false;
        });
			
      $('<div class="twitterSearchesNLoading">Loading tweets..</div>').css(opts.css['loading']).appendTo($cont);
			
      grabTweets();
			
      function grabTweets() {
        var url = root+'modules/mod_jmtwitterroll/sources/jmtwitter.php?url=statuses/user_timeline.json%3Fscreen_name='+searchTerm+'%26count='+count;
        grabFlag = false;
        grabbing = true;
        // grab twitter stream
        $.ajax({

          url: url,

          dataType: "json",
					
          timeout: 30000,
          error: function(xhr, status, e) {
            failWhale(e);
          },
          complete: function() {
            grabbing = false;
            if (opts.refreshSeconds)
              setTimeout(regrab, opts.refreshSeconds * 1000);
          },
          success: function(json) {
            if (json.error) {
              failWhale(json.error);
              return;
            }
            $cont.fadeOut('fast',function() {
              $cont.empty();
							
              // iterate twitter results 
              $.each(json, function(index,value)  {
                if (!opts.filter.call(opts, this))
                  return; // skip this tweet
                var $img, $text, w,
                tweet = opts.formatter(this, opts), 
                $tweet = $(tweet);
                $tweet.css(opts.css['tweet']);
                $img = $tweet.find('.twitterSearchesNProfileImg').css(opts.css['img']);
                $tweet.find('.twitterSearchesNUser').css(opts.css['user']);
                $tweet.find('.twitterSearchesNTime').css(opts.css['time']);
                $tweet.find('a').css(opts.css['a']);
                $tweet.appendTo($cont);
                $text = $tweet.find('.twitterSearchesNText').css(opts.css['text']);
                if (opts.avatar != 0) {
                  w = $img.outerWidth() + parseInt($tweet.css('paddingLeft')) + 10;
                  $text.css('paddingLeft', w);
                }
              });
							
              $cont.fadeIn('fast');
						
              if (json.length < 2) {
                if (opts.refreshSeconds)
                  setTimeout(grabTweets, opts.refreshSeconds * 1000);
                return;
              }

              // stage first animation
              setTimeout(go, opts.timeout);
            });
          }
        });
      }
			
      function regrab() {
        grabFlag = true;
      }
			
      function failWhale(msg) {
        var $fail = $('<div class="twitterSearchesNFail">' + msg + '</div>').css(opts.css['fail']);
        $cont.empty().append($fail);
      }
			
      function go() {
        if (paused || grabbing) {
          setTimeout(go, 500);
          return;
        }
        var h, $el = $cont.children(':first'), el = $el[0];
        $el.animate(opts.animOut, opts.animOutSpeed, function() {
          h = $el.outerHeight();
          $el.animate({
            marginTop: -h
          }, opts.animInSpeed, function() {
            $el.css({
              marginTop: 0,	
              opacity: 1
            });
            /*@cc_on
						try { el.style.removeAttribute('filter'); } // ie cleartype fix
						catch(smother) {}
						@*/
            $el.css(opts.css['tweet']).show().appendTo($cont);
						
            setTimeout(grabFlag ? grabTweets : go, opts.timeout);					
          });
        });
      }
    });
  };
	
  $.fn.twitterSearchesN.filter = function(tweet) {
    return true;
  };

  $.fn.twitterSearchesN.formatter = function(json, opts) {
    var str, pretty,
    text = json.text;
    if (opts.anchors) {
      text = json.text.replace(/(http:\/\/\S+)/g, '<a href="$1">$1</a>');
      text = text.replace(/\@(\w+)/g, '<a href="http://twitter.com/$1">@$1</a>');
    }
    str = '<div class="twitterSearchesNTweet">';
    if (opts.avatar == 1)
      str += '<img class="twitterSearchesNProfileImg" src="' + json.user.profile_image_url + '" />';
    if (opts.avatar == 2)
      str += '<i class="fa fa-twitter left"></i>';
    str += '<div><span class="twitterSearchesNUser"><a href="http://www.twitter.com/'+ searchTerm +'"/ TARGET="_blank">' 
    + json.user.name + '</a></span>';
    pretty = prettyDate(json.created_at);
    if (opts.time && pretty)
      str += ' <span class="twitterSearchesNTime">('+ pretty +')</span>'
    str += '<div class="twitterSearchesNText">' + text + '</div></div></div>';
    return str;
  };
	
  $.fn.twitterSearchesN.defaults = {
    url: 'http://search.twitter.com/search.json?callback=?&q=',
    anchors: true,				// true or false (enable embedded links in tweets)
    animOutSpeed: 500,			// speed of animation for top tweet when removed
    animInSpeed: 500,			// speed of scroll animation for moving tweets up
    animOut: {
      opacity: 0
    },	// animation of top tweet when it is removed
    applyStyles: true,			// true or false (apply default css styling or not)
    avatar: 1,				// 0,1,or 2
    bird: true,					// true or false (show or hide twitter bird image)
    birdLink: false,			// url that twitter bird image should like to
    birdSrc: 'http://cloud.github.com/downloads/malsup/twitter/tweet.gif', // twitter bird image
    filter: null,               // callback fn to filter tweets:  fn(tweetJson) { /* return false to skip tweet */ }
    formatter: null,			// callback fn to build tweet markup
    pause: true,				// true or false (pause on hover)
    refreshSeconds: 0,          // number of seconds to wait before polling for newer tweets
    term: '',					// twitter search term
    time: true,					// true or false (show or hide the time that the tweet was sent)
    timeout: 4000,				// delay betweet tweet scroll
    css: {
      // default styling
      a:     {
        textDecoration: 'none'
      },
      bird:  {
        width: '50px', 
        height: '20px', 
        position: 'absolute', 
        left: '-30px', 
        top: '-20px', 
        border: 'none'
      },
      container: {
        overflow: 'hidden', 
        height: '100%'
      },
      fail:  {
        background: '#6cc5c3 url(http://cloud.github.com/downloads/malsup/twitter/failwhale.png) no-repeat 50% 50%', 
        height: '100%', 
        padding: '10px'
      },
      frame: {  },
      tweet: {
        padding: '5px 0px', 
        clear: 'left'
      },
      img:   {
        'float': 'left', 
        margin: '5px', 
        width: '48px', 
        height: '48px'
      },
      loading: {
        padding: '20px', 
        textAlign: 'center'
      },
      text:  {},
      time:  {
        fontSize: 'smaller'
      },
      user:  {
        fontWeight: 'bold'
      }
    }
  };

  // fn to handle jsonp with timeouts and errors
  // hat tip to Ricardo Tomasi for the timeout logic
  $.getJSONP = function(s) {
    s.dataType = 'jsonp';
    $.ajax(s);

    // figure out what the callback fn is
    var $script = $(document.getElementsByTagName('head')[0].firstChild);
    var url = $script.attr('src') || '';
    var cb = (url.match(/callback=(\w+)/)||[])[1];
    if (!cb)
      return; // bail
    var t = 0, cbFn = window[cb];

    $script[0].onerror = function(e) {
      $script.remove();
      handleError(s, {}, "error", e);
      clearTimeout(t);
    };

    if (!s.timeout)
      return;

    window[cb] = function(json) {
      clearTimeout(t);
      cbFn(json);
      cbFn = null;
    };

    t = setTimeout(function() {
      $script.remove();
      handleError(s, {}, "timeout");
      if (cbFn)
        window[cb] = function(){};
    }, s.timeout);
        
    function handleError(s, o, msg, e) {
      // support jquery versions before and after 1.4.3
      ($.ajax.handleError || $.handleError)(s, o, msg, e);
    }
  };
	
  /*
	 * JavaScript Pretty Date
	 * Copyright (c) 2008 John Resig (jquery.com)
	 * Licensed under the MIT license.
	 */
  // converts ISO time to casual time
  function prettyDate(time){
    var s=new Date((time || "").replace(/-/g,"/").replace(/TZ/g," "));
    var date = new Date((time || "").replace(/-/g,"/").replace(/TZ/g," ")),
    diff = (((new Date()).getTime() - date.getTime()) / 1000),
    day_diff = Math.floor(diff / 86400);
    if ( isNaN(day_diff) || day_diff < 0 || day_diff >= 31 )
      return false;
    var v = day_diff == 0 && (
      diff < 60 && "just now" ||
      diff < 120 && "1 minute ago" ||
      diff < 3600 && Math.floor( diff / 60 ) + " minutes ago" ||
      diff < 7200 && "1 hour ago" ||
      diff < 86400 && Math.floor( diff / 3600 ) + " hours ago") ||
    day_diff == 1 && "Yesterday" ||
    day_diff < 7 && day_diff + " days ago" ||
    day_diff < 31 && Math.ceil( day_diff / 7 ) + " weeks ago";
    if (!v)
      window.console && console.log(time);
    return v ? v : '';
  }
})(jQuery);