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
        var map={};
        

        result.extracted.content.forEach(function(element) {
          console.log(element);
          //map[element.keys[0]]=element[element.keys[0]];
        }, this);

        result.extracted.map=map;
        //console.log(result);
      })

      return ctrl;
    };

    $scope.$watch(userService.currentUser, function (newValue) {
      ctrl.currentUser = newValue;
    });
  }
} ());
