/*--------------------------------------------------------------------
 # Package - JM Template
 # --------------------------------------------------------------------
 # Author - JoomlaMan http://www.joomlaman.com
 # Copyright (C) 2012 - 2013 JoomlaMan.com. All Rights Reserved.
 # Websites: http://www.JoomlaMan.com
 ---------------------------------------------------------------------*/
$jsmart = jQuery.noConflict();
window.addEvent ("load", function() {
	if($jsmart("#jm-header-wrapper")){
    $jsmart("#jm-header-wrapper").addClass('keepmenu');
		offset_top = $jsmart("#jm-header-wrapper").offset().top
		processScroll("#jm-header-wrapper", "menu-fixed", "keepmenu", offset_top);
		$jsmart(window).scroll(function(){
			processScroll("#jm-header-wrapper", "menu-fixed", "keepmenu", offset_top);
		});
	}
});
function processScroll(element, eclass, rclass, offset_top, column, offset_end) {
	var scrollTop = $jsmart(window).scrollTop();
	if($jsmart(element).height()< $jsmart(window).height()){
		if (scrollTop >= offset_top) {
			$jsmart(element).addClass(eclass);
			$jsmart(element).removeClass(rclass);
			$jsmart('ul#drilldown').css({marginTop:0});
			$jsmart('.menusys_drill').css({top:'-1px'});
		} else if (scrollTop <= offset_top) {
			$jsmart(element).removeClass(eclass);
			$jsmart(element).addClass(rclass);
			$jsmart('ul#drilldown').css({marginTop:'25px'});
			$jsmart('.menusys_drill').css({top:'0'});
		}
		if(column){
			if(scrollTop + $jsmart(element).height() > offset_end){
				$jsmart(element).removeClass(eclass);
			}
		}
	}
}

