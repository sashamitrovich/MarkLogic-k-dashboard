/* global MLSearchController */
(function () {
  'use strict';

  angular.module('app.search')
    .controller('SearchCtrl', SearchCtrl);

  SearchCtrl.$inject = ['$scope', '$location', 'userService', 'MLSearchFactory'];

  // inherit from MLSearchController
  var superCtrl = MLSearchController.prototype;
  SearchCtrl.prototype = Object.create(superCtrl);

  function SearchCtrl($scope, $location, userService, searchFactory) {
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

    $scope.$watch(userService.currentUser, function (newValue) {
      ctrl.currentUser = newValue;
    });
  }
} ());
