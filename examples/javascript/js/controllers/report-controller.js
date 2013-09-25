(function( ng, app ) {
	
	"use strict";

	app.controller( "app.ReportController", ReportController );

	// I controler the report that renders the Fusion Reactor Alert data.
	function ReportController( $scope, $window ) {

		// I am the report provided by the Fusion Reactor Alert. I contain running 
		// requests and ColdFusion threads.
		$scope.report = $scope.fusionReactorAlert.getReport();

		// I am the request that is currently being viewed.
		$scope.selectedRequest = null;

		// I keep track of the currently selected request even after the selection is
		// removed to keep the UI partially updated.
		$scope.lastSelectedRequest = null;

		// I am the view to render - requests or threads.
		$scope.subview = "runningRequests";


		// ---
		// PUBLIC METHODS.
		// ---


		// I hide the request detail modal.
		$scope.hideRequestDetail = function() {

			$scope.selectedRequest = null;

			$window.location.hash = "";

		};


		// I show the ColdFusion threads in the report.
		$scope.showColdFusionThreads = function() {

			$scope.subview = "coldfusionThreads";

		};


		// I show the details modal for the given request.
		$scope.showRequestDetail = function( runningRequest ) {

			$scope.lastSelectedRequest = $scope.selectedRequest = runningRequest;

			// Make sure we scroll back to the top of the window.
			// --
			// NOTE: This is totally a hack - this should really be isolated inside of 
			// some directive. 
			$window.setTimeout(
				function() {

					$window.location.hash = "selected-request-content";

				}
			);

		};


		// I show the running requests in the report.
		$scope.showRunningRequests = function() {

			$scope.subview = "runningRequests";

		};
		
		
		// ---
		// PRIVATE METHODS.
		// ---

	}

})( angular, app );