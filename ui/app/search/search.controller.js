/* global MLSearchController */
(function () {
  'use strict';

  var search = angular.module('app.search')
    .controller('SearchCtrl', SearchCtrl);
 
  search.filter('removeHTMLTags', function() {
    return function(text) {
      return  text ? String(text).replace(/<[^>]+>/gm, '') : '';
    };
  });

  SearchCtrl.$inject = ['$scope', '$location', 'userService', 'MLSearchFactory', '$sce', 'MLRest', '$uibModal'];

  // inherit from MLSearchController
  var superCtrl = MLSearchController.prototype;
  SearchCtrl.prototype = Object.create(superCtrl);

  function SearchCtrl($scope, $location, userService, searchFactory, $sce, mlRest, $uibModal) {
    var ctrl = this;

    var mlSearchQueries = searchFactory.newContext({ queryOptions: 'queries', pageLength: 5 });
    superCtrl.constructor.call(ctrl, $scope, $location, searchFactory.newContext());

    ctrl.init();

    ctrl.mlSearch.setTransform('transform-extracted');

    ctrl.setSnippet = function (type) {
      ctrl.mlSearch.setSnippet(type);
      ctrl.search();
    };

    // highcharts config
    ctrl.highchartConfig = {
      'options': {
        'chart': {
          'type': 'column'
        },
        plotOptions: {
          column: {
            pointPadding: 0,
            groupPadding: 0.01,
            borderWidth: 1
          },
          series: {
                cursor: 'pointer',
                point: {
                    events: {
                        click: function () {
                            //console.log('Category: ' + this.category + ', value: ' + this.y);
                            ctrl.toggleFacet("Weeks",this.category);
                        }
                    }
                }
            }
        },
        exporting: {
          enabled: false
        },
        'legend': {
          'enabled': false
        },
        'tooltip': {
          'style': {
            'padding': 10,
            'fontWeight': 'bold'
          }
        }
      },
      series: [{
        data: [10, 15, 12, 8, 7]
      }],
      'title': {
        'text': 'Weekly Trend'
      },
      xAxis: {
        /*
        title: {
          'text': 'Period'
        },*/
        categories: ['one', 'two', 'three', 'four', 'five']
      },
      // constraint name for x axis
      'xAxisCategoriesMLConstraint': 'Weeks',
      //'xAxisMLConstraint': 'Period',
      // optional constraint name for categorizing x axis values
      //'dataPointNameMLConstraint': 'Category',
      'yAxis': {
        'title': {
          'text': 'Frequency'
        }
      },
      // constraint name for y axis ($frequency is special value for value/tuple frequency)
      'yAxisMLConstraint': '$frequency',
      'zAxis': {
        'title': {
          'text': null
        }
      },
      'size': {
        'height': 250,
        'width': 250
      },
      // limit of returned results
      'resultLimit': 15
    };

    ctrl.updateSearchResults = function updateSearchResults(response) {
      superCtrl.updateSearchResults.apply(ctrl, arguments);

      // update trends chart
      ctrl.updateTrendsChart(response);

      // update d3 cloud
      ctrl.updateCloud(response);

      // get winner/looser stock
      ctrl.updateStats();

      angular.forEach(response.results, function (result, index) {
        var map = {};

        // build a nice hashmap for the exctracted elements instead of the clunky array/hashmap combination
        result.extracted.content.forEach(function (element) {
          map[ctrl.getFirstKey(element)] = ctrl.getFirstValue(element);
        }, this);

        result.extracted.elements = map;
        //console.log(map);
        //console.log(result.extracted.content);

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

        result.getNiceTitle = function() {
          //console.log("getting nicer title");
          //happens only for pdf files
          if (result.extracted.elements.type == 'pdf' || result.extracted.elements.type == 'doc') {
            var uri = result.label;
            return uri.replace(/_/g, " ").replace(".xml","");
          }
        };


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

    ctrl.updateTrendsChart = function (data) {
      if (data && !(data instanceof Array) && data.facets && data.facets.Weeks) {
        var categories = [];
        var dataSeries = [];

        angular.forEach(data.facets.Weeks.facetValues, function (value, index) {
          categories.push(value.name);
          dataSeries.push(value.count);
          //console.log('value.name:'+value.name);
          //console.log('value.count:'+value.count);
        });

        ctrl.highchartConfig.series[0].data = dataSeries;
        ctrl.highchartConfig.xAxis.categories = categories;
      }
    };

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

    ctrl.clickTag = function(e) {
      ctrl.search((ctrl.qtext ? ctrl.qtext + ' ' : '') + '"'+e.toLowerCase()+'"');
    }
    ctrl.cloudEvents = {
      'click': function (tag) {
        // stop propagation
        d3.event.stopPropagation();

        // undo default behavior of browsers to select at dblclick
        var body = document.getElementsByTagName('body')[0];
        window.getSelection().collapse(body, 0);

        // custom behavior, for instance search on dblclick
        ctrl.search((ctrl.qtext ? ctrl.qtext + ' ' : '') + '"'+tag.text.toLowerCase()+'"');
      },
      'contextmenu': function(tag) {
        console.log ('rightclick');
        d3.event.preventDefault();
        // custom behavior, for instance search on dblclick
        ctrl.search((ctrl.qtext ? ctrl.qtext + ' ' : '') + '-"'+tag.text.toLowerCase()+'"');
      }
    };

    ctrl.updateStats = function () {
      mlRest.extension('swl',
        {
          method: 'GET',
        })
        .then(function (response) {
          ctrl.stats = response.data;
        });
    }

    ctrl.open = function () {
      //console.log("loading queries");

      mlSearchQueries.search().then(function (response) {
        var model = {
          title: "Load a query",
          response: response,
          page: 1,
          search: function () {
            mlSearchQueries
              .setPage(model.page)
              .search().then(function (response) {
                model.response = response;
              });
          },
          deleteQuery: function (uri) {
            mlRest
              .deleteDocument(uri)
              .then(function () {
                model.page = 1;

                mlSearchQueries
                  .setPage(model.page)
                  .search().then(function (response) {
                    model.response = response;
                  });
              });
          }
        };

        var modalInstance = $uibModal.open({
          //animation: $scope.animationsEnabled,
          templateUrl: 'app/search/modal-open-queries.html',
          controller: 'OpenModalInstanceCtrl',
          size: 'sm',
          resolve: {
            model: function () {
              return model;
            }
          }
        });

        modalInstance.result.then(function () {
          //console.log("in result function");
        }, function () {
          //console.log('Modal dismissed at: ' + new Date());
        });
      });
    }

    ctrl.save = function () {
      //console.log('saving query');

      var modalInstance = $uibModal.open({
        //animation: $scope.animationsEnabled,
        templateUrl: 'app/search/modal-save-query.html',
        controller: 'SaveModalInstanceCtrl',
        //size: size,
        resolve: {
          query: {
            name: ctrl.currentUser.name + ' - ' + new Date().toISOString().substr(0, 16).replace('T', ''),
            url: $location.url(),
            title: 'Save Query'
          }
        }
      });

      modalInstance.result.then(function () {
        //console.log("in result function");
      }, function () {
        //console.log('Modal dismissed at: ' + new Date());
      });
    }

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

angular.module('app.search').controller('SaveModalInstanceCtrl', ['$scope', '$uibModalInstance', 'query', 'MLRest', function ($scope, $uibModalInstance, query, mlRest) {

  $scope.query = query;

  $scope.ok = function (query) {
    mlRest
      .createDocument(
      query,
      {
        extension: 'json',
        directory: '/queries/',
        collection: ['queries']
      }
      ).then(function () {
        //console.log('saved query') 
      });
    $uibModalInstance.close($scope.query);
  };

  $scope.cancel = function () {
    $uibModalInstance.dismiss('cancel');
  };
}]);

angular.module('app.search').controller('OpenModalInstanceCtrl', ['$scope', '$uibModalInstance', 'model', '$location', function ($scope, $uibModalInstance, model, $location) {

  $scope.model = model;

  $scope.ok = function (url) {
    if (url) {
      $location.url(url);
    }
    $uibModalInstance.close($scope.query);
  };

  $scope.cancel = function () {
    $uibModalInstance.dismiss('cancel');
  };
}]);
