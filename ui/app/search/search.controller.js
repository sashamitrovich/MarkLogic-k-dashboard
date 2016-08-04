/* global MLSearchController */
(function () {
  'use strict';

  angular.module('app.search')
    .controller('SearchCtrl', SearchCtrl);

  SearchCtrl.$inject = ['$scope', '$location', 'userService', 'MLSearchFactory', '$sce'];

  // inherit from MLSearchController
  var superCtrl = MLSearchController.prototype;
  SearchCtrl.prototype = Object.create(superCtrl);

  function SearchCtrl($scope, $location, userService, searchFactory, $sce) {
    var ctrl = this;

    superCtrl.constructor.call(ctrl, $scope, $location, searchFactory.newContext());

    ctrl.init();

    ctrl.mlSearch.setTransform('transform-extracted');

    ctrl.setSnippet = function (type) {
      ctrl.mlSearch.setSnippet(type);
      ctrl.search();
    };

    ctrl.updateSearchResults = function updateSearchResults(response) {
      superCtrl.updateSearchResults.apply(ctrl, arguments);

      // update d3 cloud
      ctrl.updateCloud(response);

      angular.forEach(response.results, function (result, index) {
        var map = {};

        // build a nice hashmap for the exctracted elements instead of the clunky array/hashmap combination
        result.extracted.content.forEach(function (element) {
          var myObj = ctrl.getObject(element)
          map[ctrl.getFirstKey(myObj)] = ctrl.getFirstValue(myObj);
        }, this);

        result.extracted.elements = map;
        //console.log(map);

        // for stocks, add a boolean for the value change, 
        // used to controls the styling (red for negative, green for positive)
        if (result.extracted.elements.type == 'stock') {
          var change = parseFloat(result.extracted.elements.Change);
          if (change < 0) {
            result.isNegativeChange = true
          }
          else {
            result.isNegativeChange = false;
          }
        }

        // should show match only if the matched text is not in the title of the rss news

        // if (result.extracted.elements.type == 'rss') {
        //   result.showMatch = true;
        //   var matchText = ((result.matches[0])['match-text'])[0];
        //   console.log(result.extracted.elements);
        //   console.log(matchText);
        //   console.log(result.matches);
        //   if (matchText.indexOf(result.extracted.elements.title) > -1) {
        //     result.showMatch = false;
        //   }
        // }

        //console.log(result);
      })
      return ctrl;
    };

    ctrl.words = [];

    ctrl.updateCloud = function (data) {
      if (data && data.facets && data.facets.Hashtag) {
        ctrl.words = [];
        var activeFacets = [];

        // find all selected facet values..
        angular.forEach(ctrl.mlSearch.getActiveFacets(), function (facet, key) {
          angular.forEach(facet.values, function (value, index) {
            activeFacets.push((value.value + '').toLowerCase());
          });
        });

        angular.forEach(data.facets.Hashtag.facetValues, function (value, index) {
          var q = (ctrl.qtext || '').toLowerCase();
          var val = value.name.toLowerCase();

          // suppress search terms, and selected facet values from the D3 cloud..
          if (q.indexOf(val) < 0 && activeFacets.indexOf(val) < 0) {
            ctrl.words.push({ name: value.name, score: value.count });
          }
        });
      }
      
    };

    ctrl.noRotate = function (word) {
      return 0;
    };

    ctrl.cloudEvents = {
      'dblclick': function (tag) {
        // stop propagation
        d3.event.stopPropagation();

        // undo default behavior of browsers to select at dblclick
        var body = document.getElementsByTagName('body')[0];
        window.getSelection().collapse(body, 0);

        // custom behavior, for instance search on dblclick
        ctrl.search((ctrl.qtext ? ctrl.qtext + ' ' : '') + tag.text.toLowerCase());
      }
    };

    ctrl.getObject = function (element) {
      var key = Object.keys(element)[0];
      var value = element[key];
      var newObj = {};

      if (ctrl.isObject(value)) {
        newObj = ctrl.getObject(value);
      }
      else {
        newObj = element;
      }
      return newObj;

    }

    ctrl.isObject = function (obj) {
      return obj === Object(obj);
    }

    ctrl.getFirstKey = function (myObj) {
      return Object.keys(myObj)[0];
    }

    ctrl.getFirstValue = function (myObj) {
      return myObj[ctrl.getFirstKey(myObj)];
    }

    $scope.renderHtml = function (html_code) {
      return $sce.trustAsHtml(html_code);
    };

    $scope.$watch(userService.currentUser, function (newValue) {
      ctrl.currentUser = newValue;
    });
  }
} ());
