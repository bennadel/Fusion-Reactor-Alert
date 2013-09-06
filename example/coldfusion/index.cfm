<cfscript>
	
	// Read in the email content that we are going to parse. 
	// --
	// NOTE: This was the data that was presented via the "View Original" link
	// in my Gmail. I am not sure how consistent that formatting is.
	content = fileRead( expandPath( "/sample-data/sample-1.txt" ) );

	// Parse the email into a data-structure.
	alert = new lib.FusionReactorAlert( content );

	// Get the report.
	report = alert.getReport();

</cfscript>

<cfcontent type="text/html; charset=utf-8" />

<cfoutput>

	<!doctype>
	<html>
	<head>
		<meta charset="utf=8" />

		<title>
			Fusion Reactor Alert (Report)
		</title>
	</head>
	<body id="top">

		<h1>
			Fusion Reactor Alert (Report)
		</h1>

		<p>
			Jump to: 
			<a href="##threads">Active ColdFusion Threads</a> - 
			<a href="##requests">Running Requests</a>
		</p>

		<h2 id="threads">
			Active ColdFusion Threads (CFThread)
		</h2>

		<p>
			<a href="##top">Back to Top</a>
		</p>

		<cfdump var="#report.coldfusionThreads#" />

		<h2 id="requests">
			Running Requests (Ordered By Duration)
		</h2>

		<p>
			<a href="##top">Back to Top</a>
		</p>

		<cfdump var="#report.runningRequests#" />

	</body>
	</html>

</cfoutput>