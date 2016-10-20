(function () {
  'use strict';

  angular.module('app.config')
    .controller('ConfigCtrl', ConfigCtrl);

  ConfigCtrl.$inject = ['$scope', 'MLRest', '$state', 'userService', 'ngToast'];

  function ConfigCtrl($scope, mlRest, $state, userService, toast) {
    var ctrl = this;

    angular.extend(ctrl, {
      products: ['Milk', 'Bread','Cheese']
      ,
      editorOptions: {
        plugins : 'advlist autolink link image lists charmap print preview'
      },
      addItem: addItem,
      removeItem: removeItem,
      submit: submit,
      addTag: addTag,
      removeTag: removeTag
    });

    function addItem() {
      console.log('in the list:'+ ctrl.products.indexOf(ctrl.addMe));
      ctrl.errortext = "";
      if (!ctrl.addMe) {return;}
      console.log('not empty!')
      if (ctrl.products.indexOf(ctrl.addMe) == -1) {
        ctrl.products.push(ctrl.addMe);
      } else {
        ctrl.errortext = "Can't add twice!";
      }
    }

    function removeItem(x) {
      ctrl.errortext = "";
      ctrl.products.splice(x, 1);
    }

    function submit() {
      mlRest.createDocument(ctrl.person, {
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

    $scope.$watch(userService.currentUser, function(newValue) {
      ctrl.currentUser = newValue;
    });
  }
}());
