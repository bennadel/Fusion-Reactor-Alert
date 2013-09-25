(function( ng, app ) {
	
	"use strict";

	app.factory( "FusionReactorAlert", FusionReactorAlertFactory );

	// I return the FusionReactorAlert class (but allow for dependeny-injection).
	function FusionReactorAlertFactory() {

		// I parse the given Fusion Reactor alert email content into a usable data structure
		// that can the be used to generate a report of the monitored system.
		function FusionReactorAlert( emailContent ) {

			// Normalizing the content will make the parsing easier. All of the parsing 
			// methods expect the data to be normalized.
			var content = normalizeEmailContent( emailContent );

			// Parse the primray sections of the alert email.
			var runningRequests = parseRunningRequests( content );
			var javaThreads = parseJavaThreads( content );

			// Return the public API for the component.
			return({
				getColdFusionThreads: getColdFusionThreads,
				getJavaThreads: getJavaThreads,
				getReport: getReport,
				getRunningRequests: getRunningRequests
			});


			// ---
			// PUBLIC METHODS.
			// ---


			// I return the collection of threads that were initiated via the CFThread tag.
			// This will not include CFThreads that are currently waiting to be triggered.
			function getColdFusionThreads() {

				var coldfusionThreads = [];

				for ( var i = 0, length = javaThreads.length ; i < length ; i++ ) {

					var javaThread = javaThreads[ i ];

					if ( isActiveColdFusionThread( javaThread ) ) {

						coldfusionThreads.push( javaThread );

					}

				}

				return( coldfusionThreads );

			}


			// I return the collection of all Java threads.
			function getJavaThreads() {

				return( javaThreads );

			}


			// I return a report that aggregates the running requests and the active ColdFusion
			// threads in such a way that merges meaningful and related data. The report will
			// have to sections - one for requesta and one for threads.
			function getReport() {

				var report = {
					runningRequests: getRunningRequestsReport(),
					coldfusionThreads: getColdFusionThreadsReport()
				};

				return( report );

			}


			// I return the running requests.
			function getRunningRequests() {

				return( runningRequests );

			}


			// ---
			// PRIVATE METHODS.
			// ---


			// I return the portion of the given normalized data that houses the threads and
			// stack traces.
			function extractJavaThreadsSection( content ) {

				var startOfSection = content.indexOf( "JVM Stack Trace" );

				var endOfSection = content.indexOf( "Running Requests (Full Details)" );

				var sectionContent = content.slice( startOfSection, endOfSection );

				return(
					sectionContent.replace( /JVM Stack Trace\s+-+/, "" )
				);

			}


			// I return the portion of the given normalized data that houses the running requests.
			function extractRunningRequestsSection( content ) {

				var startOfSection = content.indexOf( "Running Requests (Full Details)" );

				var sectionContent = content.slice( startOfSection );

				return( sectionContent );

			}


			// I return the report for the active ColdFusion threads.
			function getColdFusionThreadsReport() {

				var coldfusionThreads = getColdFusionThreads();

				var report = [];

				for ( var i = 0, length = coldfusionThreads.length ; i < length ; i++ ) {

					var coldfusionThread = coldfusionThreads[ i ];

					report.push({
						jvmID: coldfusionThread.jvmID,
						threadID: coldfusionThread.threadID,
						isCFThread: coldfusionThread.isCFThread,
						hashcode: coldfusionThread.hashcode,
						priority: coldfusionThread.priority,
						stacktrace: coldfusionThread.stacktrace
					});

				}

				return( report );

			}


			// I return the Java thread with the given ID. Or, NULL if not found.
			function getJavaThreadByID( threadID ) {

				for ( var i = 0, length = javaThreads.length ; i < length ; i++ ) {

					var javaThread = javaThreads[ i ];

					if ( javaThread.threadID == threadID ) {

						return( javaThread );

					}

				}

				return( null );

			}


			// I return the report for the running requests.
			function getRunningRequestsReport() {

				var report = [];

				for ( var i = 0, length = runningRequests.length ; i < length ; i++ ) {

					var runningRequest = runningRequests[ i ];

					report.push({
						requestID: runningRequest.requestID,
						requestUrl: runningRequest.requestUrl,
						status: runningRequest.status,
						startedAt: ( runningRequest.startedAt * 1 ),
						startedAtDate: runningRequest.startedAtDate,
						threadID: runningRequest.threadID,
						ipAddress: runningRequest.ipAddress,
						method: runningRequest.method,
						duration: ( runningRequest.duration * 1 ),
						usedMemoryPercent: runningRequest.usedMemoryPercent,
						maxMemoryKB: ( runningRequest.maxMemoryKB * 1 ),
						usedMemoryKB: ( runningRequest.usedMemoryKB * 1 ),
						totalMemoryKB: ( runningRequest.totalMemoryKB * 1 ),
						freeMemoryKB: ( runningRequest.freeMemoryKB * 1 ),
						queryString: runningRequest.queryString,
						statusCode: runningRequest.statusCode,
						cpuTime: ( runningRequest.cpuTime * 1 ),
						jdbcQueriesRun: ( runningRequest.jdbcQueriesRun * 1 ),
						jdbcTotalTime: ( runningRequest.jdbcTotalTime * 1 ),
						jdbcTotalExecutionTime: ( runningRequest.jdbcTotalExecutionTime * 1 ),
						jdbcTotalRowCount: ( runningRequest.jdbcTotalRowCount * 1 ),
						amfRquest: runningRequest.amfRquest,
						bytesSent: ( runningRequest.bytesSent * 1 ),
						timeToFirstByte: ( runningRequest.timeToFirstByte * 1 ),
						timeToLastByte: ( runningRequest.timeToLastByte * 1 ),
						timeToStreamOpen: ( runningRequest.timeToStreamOpen * 1 ),
						timeToStreamClose: runningRequest.timeToStreamClose,
						userAgent: runningRequest.userAgent
					});

					// Add the related thread.
					var relatedThread = getJavaThreadByID( runningRequest.threadID );

					if ( relatedThread ) {

						report[ i ].thread = relatedThread;

					}

				}

				// Order by the longest running requests first.
				report.sort(
					function( a, b ) {

						return( a.duration > b.duration ? -1 : 1 );

					}
				);

				return( report );

			}


			// I determine if the given Java thread represents a CFThread.
			function isActiveColdFusionThread( javaThread ) {

				return(
					javaThread.isCFThread &&
					javaThread.stacktrace.length &&
					( javaThread.stacktrace[ 0 ].code.indexOf( "java.lang.Object.wait" ) === -1 )
				);

			}


			// I normalize the email content, removing whitespace oddities caused by email formatting.
			function normalizeEmailContent( emailContent ) {

				var content = trim( emailContent );

				// Standardize the linebreaks.
				content = content.replace( /\r\n?|\n/g, "\n" );

				// Strip out all the leading / trailgin white space on each line.
				content = content.replace( /^[ 	]+|[ 	]+$/gm, "" );

				// Make sure all URLs on the line they are supposed to be on - some URLs wrap to the next line.
				content = content.replace( /\n(http)/g, " $1" );

				// Fix line breaks in some of the stack-trace items.
				content = content.replace( /\[Native\s+Method\]/g, "[Native Method]" );

				// Remove any line breaks from the Fusion Reactor thread IDs.
				content = content.replace( /(FusionReactor Web Server \([^\n)]+)\n([^)\n]+\))/g, "$1 $2" );

				// Remove any line breaks from user-agent strings.
				content = content.replace( /(User Agent:)([^\n]+)(?:\n)([^\s][^\n]*)/g, "$1$2 $3" );

				// Remove streamin-data references. These are only going to complicate parsing.
				content = content.replace( /\[Note: Data is still streaming\]/g, "" );

				return( content );

			}


			// I parse a single running-request content item into a key-value collection.
			function parseRunningRequest( content ) {

				var requestProperties = {};

				// Change the keys into something more appropriate for parsing and for data structures. 
				// Each of the values preceding the ":" will become a key in the resultant collection.
				content = content.replace( "Request ID", "requestID" );
				content = content.replace( "Request URL", "requestUrl" );
				content = content.replace( "Status", "status" );
				content = content.replace( "Started (Milliseconds)", "startedAt" );
				content = content.replace( "Started (Date/Time)", "startedAtDate" );
				content = content.replace( "Thread ID", "threadID" );
				content = content.replace( "Client IP Address", "ipAddress" );
				content = content.replace( "Request Method", "method" );
				content = content.replace( "Execution Time (ms)", "duration" );
				content = content.replace( "Used Memory (percentage)", "usedMemoryPercent" );
				content = content.replace( "Max Memory (KB)", "maxMemoryKB" );
				content = content.replace( "Used Memory (KB)", "usedMemoryKB" );
				content = content.replace( "Total Memory (KB)", "totalMemoryKB" );
				content = content.replace( "Free Memory (KB)", "freeMemoryKB" );
				content = content.replace( "Query String", "queryString" );
				content = content.replace( "Return Status Code", "statusCode" );
				content = content.replace( "CPU Time (ms)", "cpuTime" );
				content = content.replace( "JDBC Queries Run", "jdbcQueriesRun" );
				content = content.replace( "JDBC Total Time", "jdbcTotalTime" );
				content = content.replace( "JDBC Total Execution Time", "jdbcTotalExecutionTime" );
				content = content.replace( "JDBC Total Row Count", "jdbcTotalRowCount" );
				content = content.replace( "AMF Request", "amfRquest" );
				content = content.replace( "Bytes Sent", "bytesSent" );
				content = content.replace( "Time to First Byte (ms)", "timeToFirstByte" );
				content = content.replace( "Time to Last Byte (ms)", "timeToLastByte" );
				content = content.replace( "Time to Stream Open (ms)", "timeToStreamOpen" );
				content = content.replace( "Time to Stream Close (ms)", "timeToStreamClose" );
				content = content.replace( "User Agent", "userAgent" );

				// Get the individual lines of content.
				var parts = content.split( /\n+/g );

				// For each line, break up the key/value pair based on the first ":" instance.
				for ( var i = 0, length = parts.length ; i < length ; i++ ) {

					var part = parts[ i ];
					var indexOfDelimiter = part.indexOf( ":" );
					var key = trim( part.slice( 0, indexOfDelimiter ) );
					var value = trim( part.slice( indexOfDelimiter + 1 ) );

					requestProperties[ key ] = value;

				}
				
				return( requestProperties );

			}


			// I parse the running requests into an array of data structures.
			function parseRunningRequests( content ) {

				var runningRequests = [];

				var sectionContent = extractRunningRequestsSection( content );

				var parts = sectionContent.match( /Request ID:((?!Request ID:)[\s\S])+/g );

				for ( var i = 0, length = parts.length ; i < length ; i++ ) {

					var part = parts[ i ];

					runningRequests.push( parseRunningRequest( trim( part ) ) );

				}

				return( runningRequests );

			}


			// I parse a single Java thread content item into a key-value collection.
			function parseJavaThread( content ) {

				var javaThreadProperties = {};

				// Each Java thread is composed of two different parts - the thread information and 
				// the actual stack trace information. The two sections are separated by a double line-
				// break.
				// --
				// NOTE: Not all threads will report a stack trace.
				var doubleLineBreakIndex = content.search( /\n{2}/i );

				// If the stack-trace doesn't have any content, we'll only have key-value pairs.
				if ( doubleLineBreakIndex >= 0 ) {

					var propertyContent = trim( content.slice( 0, doubleLineBreakIndex ) );
					var stacktraceContent = trim( content.slice( doubleLineBreakIndex + 1 ) );

				} else {

					var propertyContent = content;
					var stacktraceContent = "";
				}
			 
				// Change the keys in the property content into something more appropriate for parsing 
				// and for data structures. Each of the values preceding the ":" will become a key in
				// the resultant collection.
				propertyContent = propertyContent.replace( "JVM ID", "jvmID" );
				propertyContent = propertyContent.replace( "Thread ID", "threadID" );
				propertyContent = propertyContent.replace( "Priority", "priority" );
				propertyContent = propertyContent.replace( "Hashcode", "hashcode" );

				// Get the individual lines of content.
				var parts = propertyContent.split( /\n+/g );

				// For each line, break up the key/value pair based on the first ":" instance.
				for ( var i = 0, length = parts.length ; i < length ; i++ ) {

					var part = parts[ i ];
					var indexOfDelimiter = part.indexOf( ":" );

					var key = trim( part.slice( 0, indexOfDelimiter ) );
					var value = trim( part.slice( indexOfDelimiter + 1 ) );

					javaThreadProperties[ key ] = value;

				}

				// Add a flag to differentiate ColdFusion threads (initiated via the CFThread tag) from
				// the other Java threads that are running the entire J2EE application.
				javaThreadProperties.isCFThread = ( javaThreadProperties.threadID.search( /^cfthread-/i ) === 0 );

				// Now, add the raw stack trace data, if we have any.
				if ( stacktraceContent.length ) {

					var stacktrace = stacktraceContent.split( /\n+/g );

				} else {

					var stacktrace = [];
					
				}

				// Now that we have the raw stacktrace split up into individual code items, we
				// want to wrap those items in something that attempts to categorize each stack 
				// trace item more fully.
				javaThreadProperties.stacktrace = [];

				// As an optimization, we'll pull out the ColdFusion stacktrace items on their own.
				javaThreadProperties.coldfusionStacktrace = [];

				// As we prepare the stacktrace items, we want to keep track of whether any of 
				// them contain ColdFusion references. 
				javaThreadProperties.hasColdFusion = false;

				var coldfusionPattern = /\.(cfm|cfc)/i;

				// Prepare the items.
				for ( var i = 0 ; i < stacktrace.length ; i++ ) {

					var item = {
						code: stacktrace[ i ]
					};

					javaThreadProperties.stacktrace.push( item );

					item.isColdFusion = coldfusionPattern.test( item.code );

					// If any of the items contain a ColdFusion reference, flag the thread as
					// containing visible ColdFusion data.
					if ( item.isColdFusion ) {

						javaThreadProperties.hasColdFusion = true;

						// Track this item in the ColdFusion-specific list as well.
						javaThreadProperties.coldfusionStacktrace.push( item );

					}				

				}

				return( javaThreadProperties );

			}


			// I parse the Java threads into an array of data structures.
			function parseJavaThreads( content ) {

				var javaThreads = [];

				var sectionContent = extractJavaThreadsSection( content );

				var parts = sectionContent.match( /JVM ID:((?!---------)[\s\S])+/g );

				for ( var i = 0, length = parts.length ; i < length ; i++ ) {

					var part = parts[ i ];

					javaThreads.push( parseJavaThread( part ) );

				}

				return( javaThreads );

			}


			// I trim the given value of leading and trailing whitespace.
			function trim( value ) {

				return(
					value.replace( /^\s+|\s+$/g, "" )
				);

			}

		}


		// Return the constructor.
		return( FusionReactorAlert );

	}
	
})( angular, app );