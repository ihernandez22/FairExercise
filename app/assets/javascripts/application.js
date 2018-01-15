//= require rails-ujs
//= require_tree .
//= require bootstrap-sprockets

function escape_js(str) {
  return $("<div>").html(str).text();
}
