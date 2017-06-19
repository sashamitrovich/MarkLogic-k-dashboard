(function () {
  'use strict';

  angular.module('app.config')
    .controller('ConfigCtrl', ConfigCtrl);

  ConfigCtrl.$inject = ['doc', '$scope', 'MLRest', '$state', 'ngToast', '$http', 'Upload', '$timeout'];

  function ConfigCtrl(doc, $scope, mlRest, $state, toast, $http, Upload) {
    var ctrl = this;

    angular.extend(ctrl, {
      products: ['Milk', 'Bread', 'Cheese']
      ,
      editorOptions: {
        plugins: 'advlist autolink link image lists charmap print preview'
      },
      addRssItem: addRssItem,
      removeRssItem: removeRssItem,
      addTwitterItem: addTwitterItem,
      removeTwitterItem: removeTwitterItem,
      updateSources: updateSources,
      submit: submit,
      addTag: addTag,
      removeTag: removeTag,
      sources: doc.data, // {rss: ["1","2"], twitter:["t1","t2","t3"]},
      configDownloadUri: '/v1/documents?uri=' + encodeURIComponent('/config/sources.json') 
    });

    // for uploading the sources config file
    ctrl.uploadFiles = function (file, errFiles) {
      updateConfig(file);
    };


    // ml-uploader config
    ctrl.fileList = [];


    ctrl.uploadOptions = {
      'collection': ['pdf', 'binary'],
      'trans:tags': ['tag1', 'tag2'],
      // uriPrefix 
      'uriPrefix': function (file) {
        var extension = file.name.replace('^.*\.([^\.]+)$');
        //return '/internal/dropped/' + extension + '/';
        return '/internal/dropped/';
      }
    };

    ctrl.deletePdfContent = function () {
      toast.info('working...');
      $http({
        url: '/v1/search',
        method: 'DELETE',
        params: {
          collection: 'pdf'
        }
      }).then(function (response) {
        toast.success('Deleted PDF content');
        $scope.$broadcast('refresh');
      }, function (response) {
        toast.danger(response.data);
      });
    };

    ctrl.deleteRssContent = function () {
      toast.info('working...');
      $http({
        url: '/v1/search',
        method: 'DELETE',
        params: {
          collection: 'data/rss'
        }
      }).then(function (response) {
        toast.success('Deleted RSS content');
        $scope.$broadcast('refresh');
      }, function (response) {
        toast.danger(response.data);
      });
    };

    ctrl.deleteTwitterContent = function () {
      toast.info('working...');
      $http({
        url: '/v1/search',
        method: 'DELETE',
        params: {
          collection: 'data/twitter'
        }
      }).then(function (response) {
        toast.success('Deleted Twitter content');
        $scope.$broadcast('refresh');
      }, function (response) {
        toast.danger(response.data);
      });
    };

    ctrl.importTweets = function () {
      toast.info('working...');
      $http({
        url: '/v1/resources/tweets',
        method: 'PUT'
      }).then(function (response) {
        toast.success('Imported status tweets');
        $scope.$broadcast('refresh');
      }, function (response) {
        toast.danger(response.data);
      });
    };

    ctrl.importRss = function () {
      toast.info('working...');
      console.log(ctrl.sources.semantics.enrich);
      $http({
        url: '/v1/resources/rss',
        method: 'PUT' /*,
        params:{'rs:enrich':ctrl.sources.semantics.enrich} */
      }).then(function (response) {
        toast.success('Imported RSS feeds');
        $scope.$broadcast('refresh');
      }, function (response) {
        toast.danger(response.data);
      });
    };

    function getConfig() {
      return MLRest.getDocument('/config/sources.json', { format: 'json' }).then(function (response) {
        return response.data;
      });
    }

    function updateConfig(config) {
      console.log('updating configuration')
      mlRest.updateDocument(config, {
        format: 'json',
        uri: '/config/sources.json'
        // TODO: add read/update permissions here like this:
        // 'perm:sample-role': 'read',
        // 'perm:sample-role': 'update'
      }).then(function (response) {
        toast.success('Configuration saved');
        //$state.go('root.view', { uri: response.replace(/(.*\?uri=)/, '') });
        $state.go($state.current, {}, { reload: true });
      });
    }

    function updateSources() {
      updateConfig(ctrl.sources);
    }

    function addRssItem() {
      if (!ctrl.addMeRss) { ctrl.errortextRss = "Can't add an empty element!"; return; }
      console.log('entry not empty!')

      var rss = {};
      rss.link = ctrl.addMeRss;
      if (ctrl.addMeEncoding) {
        rss.encoding = ctrl.addMeEncoding;
      }
      else {
        rss.encoding = "utf-8";
      }

      ctrl.errortextRss = "";
      var pos = ctrl.sources.rss.map(function (e) { return e.link; }).indexOf(rss.link)
      //console.log("pos=", pos);

      if (pos == -1) {
        ctrl.sources.rss.push(rss);
        ctrl.addMeRss = "";

        console.log(ctrl.sources)
      } else {
        ctrl.errortextRss = "Can't add twice!";
      }
    }

    function removeRssItem(x) {
      ctrl.errortext = "";
      ctrl.sources.rss.splice(x, 1);
    }

    function addTwitterItem() {
      //console.log('in the list:' + ctrl.sources.twitter.indexOf(ctrl.addMe));
      ctrl.errortext = "";
      if (!ctrl.addMeTwitter) { ctrl.errortextTwitter = "Can't add an empty element!"; return; }
      console.log('not empty!')
      if (ctrl.sources.twitter.indexOf(ctrl.addMeTwitter) == -1) {
        ctrl.sources.twitter.push(ctrl.addMeTwitter);
        ctrl.addMeTwitter = "";
      } else {
        ctrl.errortextTwitter = "Can't add twice!";
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
      }).then(function (response) {
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

    ctrl.clickedSemanticsCheckbox = function clickedSemanticsCheckbox() {
      //if (ctrs.sources.semantics.enrich==true)
      console.log('in clickedSemanticsCheckbox()!')
    }


    /*
    $scope.$watch(userService.currentUser, function(newValue) {
      ctrl.currentUser = newValue;
    });
    */
  }
}());
