/* jshint node:true,esnext:true */
/* global xdmp */

var json = require('/MarkLogic/json/json.xqy');


function toJson(context, params, content) {
  'use strict';

  var config = json.config('custom');
  config["array-element-names"]="tags";
  var response = content.toObject();

  if (response.results) {
    response.results.map(function (result) {
      //just do this for xml docs
      if (result.uri.match("json") == null) {
        
        if (result.extracted && result.extracted.content) {
          //xdmp.log("result.extracted.content="+result.extracted.content);
          result.extracted.content.map(function (content, index) {
            if (content.match(/^</) && !content.match(/^<!/)) {
              result.extracted.content[index] = json.transformToJson(xdmp.unquote(content), config);
            }
          });
        }
      }
    });
  }

  //console.log(response.results[0].extracted)
  return response;
}

exports.transform = toJson;