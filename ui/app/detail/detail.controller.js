/* global X2JS,vkbeautify */
(function () {
  'use strict';
  angular.module('app.detail')
  .controller('DetailCtrl', DetailCtrl);

  DetailCtrl.$inject = ['doc', '$stateParams'];
  function DetailCtrl(doc, $stateParams) {
    var ctrl = this;

    var uri = $stateParams.uri;
    var qtext=$stateParams.q;
    var urixml=uri;

    var contentType = doc.headers('content-type');

    var x2js = new X2JS();
    /* jscs: disable */
    if (contentType.lastIndexOf('application/json', 0) === 0) {
      /*jshint camelcase: false */
      ctrl.xml = vkbeautify.xml(x2js.json2xml_str(doc.data));
      ctrl.json = doc.data;
      ctrl.type = 'json';
    } else if (uri.indexOf("/internal/dropped/doc")>-1) {
      ctrl.type = 'doc';
      uri = uri.replace("xml","doc");
      //console.log(uri);
    } else if (uri.indexOf("/internal/dropped/pdf")>-1) {
      ctrl.type = 'pdf';
      uri = uri.replace("xml","pdf");
      //console.log(uri);
    } else if (contentType.lastIndexOf('application/xml', 0) === 0) {
      ctrl.xml = vkbeautify.xml(doc.data);
      /*jshint camelcase: false */
      ctrl.json = x2js.xml_str2json(doc.data);
      ctrl.type = 'xml';
      /* jscs: enable */
    } else if (contentType.lastIndexOf('text/plain', 0) === 0) {
      ctrl.xml = doc.data;
      ctrl.json = {'Document' : doc.data};
      ctrl.type = 'text';
    } else if (contentType.lastIndexOf('application', 0) === 0 ) {
      ctrl.xml = 'Binary object';
      ctrl.json = {'Document type' : 'Binary object'};
      ctrl.type = 'binary';
    } else {
      ctrl.xml = 'Error occured determining document type.';
      ctrl.json = {'Error' : 'Error occured determining document type.'};
    }

    angular.extend(ctrl, {
      doc : doc.data,
      uri : uri,
      viewuri : '/v1/documents?uri='+encodeURIComponent(uri),
      viewurihtml: '/v1/documents?uri='+encodeURIComponent(urixml) +'&transform=get-html&trans:q='+qtext /*'&format=xml&transform=indent&trans:property=html'*/
    });
  }
}());
