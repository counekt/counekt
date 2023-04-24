var map = L.map('map').setView([55.676111, 12.568333], 13);
         
         //CartoDB layer names: light_all / dark_all / light_nonames / dark_nonames
         layer = L.tileLayer('http://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png', {
            attribution: '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors, &copy; <a href="http://cartodb.com/attributions">CartoDB</a>',
            subdomains: 'abcd',
            maxZoom: 13,
            minZoom: 2
         }).addTo(map);
         // Create additional Control placeholders

  function addControlPlaceholders(map) {
    var corners = map._controlCorners,
        l = 'leaflet-',
        container = map._controlContainer;

    function createCorner(vSide, hSide) {
        var className = l + vSide + ' ' + l + hSide;

        corners[vSide + hSide] = L.DomUtil.create('div', className, container);
    }

    createCorner('verticalcenter', 'left');
    createCorner('verticalcenter', 'right');
}
addControlPlaceholders(map);

// Change the position of the Zoom Control to a newly created placeholder.
map.zoomControl.setPosition('bottomright');

// You can also put other controls in the same placeholder.

map.attributionControl.setPrefix(''); // Don't show the 'Powered by Leaflet' text. Attribution overload
$(document).ready(function() {
setTimeout(function(){ 
  $("#map-container").height($(window).height());map.invalidateSize();
  $("#explore-box").height(Math.min(375, Math.max(55, $(window).height()-100)));
}, 250);

       });

$(window).on("resize", function () {
   $("#map-container").height($(window).height());
   map.invalidateSize();
     $("#explore-box").height(Math.min(375, Math.max(55, $(window).height()-100)));


 }).trigger("resize");

var proIcon = L.icon({
    iconUrl: 'static/images/pro-pic.png',

    iconSize:     [25, 25], // size of the icon
    iconAnchor:   [12.5, 12.5], // point of the icon which will correspond to marker's location
    popupAnchor:  [-2, 0] // point from which the popup should open relative to the iconAnchor
});
