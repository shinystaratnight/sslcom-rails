//= require jquery
//= require jquery_ujs

//= require jquery.prettyPhoto.js
//= require jquery.prettyLoader.js
//= require jquery.prettyPopin.js
//= require jquery.form.js

//= require jquery.livequery.js
//= require multifile/jquery.MetaData.js
//= require multifile/jquery.MultiFile.pack.js
//= require multifile/jquery.blockUI.js
//= require jquery-ui-1.8.7.custom.min.js
//= require jquery.cookie.js
//= require jquery.json-2.2.min.js
//= require jquery.tooltip.min.js
//= require jCal.js
//= require datejs.js

//= require_self
//= require_tree .

// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

function remove_fields(link) {
   $(link).prev("input[type=hidden]").val("1");
   $(link).closest(".fields").hide();
}

function add_fields(link, association, content) {
   var new_id = new Date().getTime();
   var regexp = new RegExp("new_" + association, "g");
   $(link).parent().before(content.replace(regexp, new_id));
}

$.ajaxSettings.dataType = "json";
