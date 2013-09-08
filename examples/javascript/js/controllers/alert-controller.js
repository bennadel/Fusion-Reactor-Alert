(function( ng, app ) {
	
	"use strict";

	app.controller( "app.AlertController", AlertController );

	// I controler the Fusion Reactor Alert email viewing interface.
	function AlertController( $scope, FusionReactorAlert ) {

		// I determine which view to render.
		$scope.subview = "input";

		// I contain the raw, unparsed email content (bound using ngModel).
		$scope.form = {
			emailContent: ""
		};

		// I contain the parsed email alert.
		$scope.fusionReactorAlert = null;


		// ---
		// PUBLIC METHODS.
		// ---


		// I parse the user-provided email content and show it in the report view.
		$scope.showReport = function() {

			if ( ! $scope.form.emailContent ) {

				return;

			}

			$scope.fusionReactorAlert = new FusionReactorAlert( $scope.form.emailContent );

			$scope.subview = "output";

		};


		// ---
		// PRIVATE METHODS.
		// ---

	}

})( angular, app );