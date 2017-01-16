(function () {
  'use strict';

  angular.module('app.config')
    .controller('ConfigCtrl', ConfigCtrl);

  ConfigCtrl.$inject = ['doc','$scope', 'MLRest', '$state'];

  function ConfigCtrl(doc, $scope, mlRest, $state) {
    var ctrl = this;

    console.log("doc=", doc.data);


    angular.extend(ctrl, {
      products: ['Milk', 'Bread','Cheese']
      ,
      editorOptions: {
        plugins : 'advlist autolink link image lists charmap print preview'
      },
      addRssItem: addRssItem,
      removeRssItem: removeRssItem,
      addTwitterItem: addTwitterItem,
      removeTwitterItem: removeTwitterItem,
      submit: submit,
      addTag: addTag,
      removeTag: removeTag,
      sources: doc.data // {rss: ["1","2"], twitter:["t1","t2","t3"]}
    });

    function addRssItem() {
      console.log('in the list:'+ ctrl.sources.rss.indexOf(ctrl.addMe));
      ctrl.errortext = "";
      if (!ctrl.addMe) {return;}
      console.log('not empty!')
      if (ctrl.sources.rss.indexOf(ctrl.addMe) == -1) {
        ctrl.sources.rss.push(ctrl.addMe);
      } else {
        ctrl.errortext = "Can't add twice!";
      }
    }

    function removeRssItem(x) {
      ctrl.errortext = "";
      ctrl.sources.rss.splice(x, 1);
    }

    function addTwitterItem() {
      console.log('in the list:'+ ctrl.sources.twitter.indexOf(ctrl.addMe));
      ctrl.errortext = "";
      if (!ctrl.addMe) {return;}
      console.log('not empty!')
      if (ctrl.sources.twitter.indexOf(ctrl.addMe) == -1) {
        ctrl.sources.twitter.push(ctrl.addMe);
      } else {
        ctrl.errortext = "Can't add twice!";
      }
    }

    function removeTwitterItem(x) {
      ctrl.errortext = "";
      ctrl.sources.twitter.splice(x, 1);
    }

    function submit() {
      mlRest.createDocument(ctrl.products, {
        format: 'json',
        directory: '/content/',
        extension: '.json',
        collection: ['data', 'data/people']
        // TODO: add read/update permissions here like this:
        // 'perm:sample-role': 'read',
        // 'perm:sample-role': 'update'
      }).then(function(response) {
        toast.success('Record created.');
        $state.go('root.view', { uri: response.replace(/(.*\?uri=)/, '') });
      });
    }

    function addTag() {
      if (ctrl.newTag && ctrl.newTag !== '' && ctrl.person.tags.indexOf(ctrl.newTag) < 0) {
        ctrl.person.tags.push(ctrl.newTag);
      }
      ctrl.newTag = null;
    }

    function removeTag(index) {
      ctrl.person.tags.splice(index, 1);
    }

    /*
    $scope.$watch(userService.currentUser, function(newValue) {
      ctrl.currentUser = newValue;
    });
    */
  }
}());
