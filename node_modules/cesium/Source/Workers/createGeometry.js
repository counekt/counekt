/* This file is automatically rebuilt by the Cesium build process. */
define(['./when-e6985d2a', './Check-24cae389', './Math-392d0035', './Cartesian2-a5d6dde9', './Transforms-81680c41', './RuntimeError-61701d3e', './WebGLConstants-34c08bc0', './ComponentDatatype-cb08e294', './GeometryAttribute-6d403cd9', './GeometryAttributes-d6ea8c2b', './AttributeCompression-114c6354', './GeometryPipeline-e8a01ba6', './EncodedCartesian3-c758025f', './IndexDatatype-1be7d1f8', './IntersectionTests-f17c84f0', './Plane-ac6a1d3e', './PrimitivePipeline-8b63e52c', './WebMercatorProjection-a06fbf17', './createTaskProcessorWorker'], function (when, Check, _Math, Cartesian2, Transforms, RuntimeError, WebGLConstants, ComponentDatatype, GeometryAttribute, GeometryAttributes, AttributeCompression, GeometryPipeline, EncodedCartesian3, IndexDatatype, IntersectionTests, Plane, PrimitivePipeline, WebMercatorProjection, createTaskProcessorWorker) { 'use strict';

  /* global require */

  var moduleCache = {};

  function getModule(moduleName) {
    var module = moduleCache[moduleName];
    if (!when.defined(module)) {
      if (typeof exports === "object") {
        // Use CommonJS-style require.
        moduleCache[module] = module = require("Workers/" + moduleName);
      } else {
        // Use AMD-style require.
        // in web workers, require is synchronous
        require(["Workers/" + moduleName], function (f) {
          module = f;
          moduleCache[module] = f;
        });
      }
    }
    return module;
  }

  function createGeometry(parameters, transferableObjects) {
    var subTasks = parameters.subTasks;
    var length = subTasks.length;
    var resultsOrPromises = new Array(length);

    for (var i = 0; i < length; i++) {
      var task = subTasks[i];
      var geometry = task.geometry;
      var moduleName = task.moduleName;

      if (when.defined(moduleName)) {
        var createFunction = getModule(moduleName);
        resultsOrPromises[i] = createFunction(geometry, task.offset);
      } else {
        //Already created geometry
        resultsOrPromises[i] = geometry;
      }
    }

    return when.when.all(resultsOrPromises, function (results) {
      return PrimitivePipeline.PrimitivePipeline.packCreateGeometryResults(
        results,
        transferableObjects
      );
    });
  }
  var createGeometry$1 = createTaskProcessorWorker(createGeometry);

  return createGeometry$1;

});
