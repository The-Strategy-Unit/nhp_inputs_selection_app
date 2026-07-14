document.addEventListener('DOMContentLoaded', function () {

  // Initialize the map and centre it roughly on the UK
  const map = L.map('provider_peers_map').setView([54.7, -2.6], 6);
  // set up some variables which we will load values into later
  let providersGeojson = null;
  let providersLayer = null;
  let selectedOrgIds = null;

  // Add a tile layer to the map (using Carto's light basemap)
  L.tileLayer(
    'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
    {
      subdomains: 'abcd',
      maxZoom: 10,
      attribution: '&copy; OpenStreetMap contributors &copy; CARTO'
    }
  ).addTo(map);

  // Function to determine marker color based on whether the org_id matches the selected dataset
  // based on the provider dropdown.
  function markerColor(orgId) {
    let currentDataset = Shiny.shinyapp.$inputValues["dataset"];
    return (currentDataset && orgId === currentDataset) ? '#e67e22' : '#3498db';
  }

  // Function to render the points for the selected peers on the map
  function renderProvidersLayer() {
    // check that the providersGeojson has been loaded before trying to filter and render it
    if (!providersGeojson) {
      return;
    }

    // the providersGeojson contains all the providers, we filter it to only include the current
    // provider and its peers
    const filteredFeatures = providersGeojson.features.filter((feature) => {
      // check that shiny has sent the peers to filter to. if it hasn't yet, don't show any points
      if (!selectedOrgIds || selectedOrgIds.size === 0) {
        return false;
      }
      // check if the current feature is in the selected peers list
      return selectedOrgIds.has(feature.properties.org_id);
    });

    // remove the existing providersLayer from the map if it exists, so we can replace it with the
    // new filtered layer
    if (providersLayer) {
      map.removeLayer(providersLayer);
    }

    // generate a new layer with the filtered features and add it to the map. this layer will be
    // styled with circle markers and popups for each provider's name, coloured based on whether it
    // is the selected dataset or a peer.
    providersLayer = L.geoJSON(
      {
        type: 'FeatureCollection',
        features: filteredFeatures
      },
      {
        pointToLayer: function (feature, latlng) {
          return L.circleMarker(latlng, {
            radius: 5,
            fillColor: markerColor(feature.properties.org_id),
            color: '#ffffff',
            weight: 1,
            opacity: 1,
            fillOpacity: 0.9
          });
        },
        onEachFeature: function (feature, layer) {
          if (feature.properties && feature.properties.name) {
            layer.bindPopup(feature.properties.name);
          }
        }
      }
    ).addTo(map);
  }

  // asynchronously load the provider_locations.geojson file and store it in the providersGeojson
  // variable. once loaded, call renderProvidersLayer to display the points on the map.
  fetch('provider_locations.geojson')
    .then((response) => {
      if (!response.ok) {
        throw new Error('Failed to load provider_locations.geojson');
      }
      return response.json();
    })
    .then((geojson) => {
      providersGeojson = geojson;
      renderProvidersLayer();
    })
    .catch((error) => {
      console.error('Error loading provider_locations.geojson:', error);
    });

  // listen for messages from shiny containing the selected peers. when received, store the org_ids
  // in a Set and call renderProvidersLayer to update the map with the new selection.
  Shiny.addCustomMessageHandler('selectedPeersUpdate', function (message) {
    selectedOrgIds = new Set(message || []);
    renderProvidersLayer();
  });

});