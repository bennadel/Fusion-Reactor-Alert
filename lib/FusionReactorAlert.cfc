component
	output = false
	hint = "I convert a raw Fusion Reactor alert email into a data structure."
	{

	// I return the initialized component.
	public any function init( required string emailContent ) {

		// Normalizing the content will make the parsing easier. All of the parsing 
		// methods expect the data to be normalized.
		var content = normalizeEmailContent( emailContent );

		// Parse the primray sections of the alert email.
		runningRequests = parseRunningRequests( content );
		javaThreads = parseJavaThreads( content );

		return( this );

	}


	// ---
	// PUBLIC METHODS.
	// ---


	// I return the collection of threads that were initiated via the CFThread tag.
	// This will not include CFThreads that are currently waiting to be triggered.
	public array function getColdFusionThreads() {

		var coldfusionThreads = [];

		for ( var javaThread in javaThreads ) {

			if ( isActiveColdFusionThread( javaThread ) ) {

				arrayAppend( coldfusionThreads, javaThread );

			}

		}

		return( coldfusionThreads );

	}


	// I return the collection of all Java threads.
	public array function getJavaThreads() {

		return( javaThreads );

	}


	// I return a report that aggregates the running requests and the active ColdFusion threads
	// in such a way that merges meaningful and related data. The report will have to sections - 
	// one for requesta and one for threads.
	public structure function getReport() {

		var report = {
			runningRequests = getRunningRequestsReport(),
			coldfusionThreads = getColdFusionThreadsReport()
		};

		return( report );

	}


	// I return the running requests.
	public array function getRunningRequests() {

		return( runningRequests );

	}


	// ---
	// PRIVATE METHODS.
	// ---


	// I return the portion of the given normalized data that houses the threads and stack traces.
	private string function extractJavaThreadsSection( required string content ) {

		var startOfSection = find( "JVM Stack Trace", content );

		var endOfSection = find( "Running Requests (Full Details)", content );

		var sectionContent = mid( content, startOfSection, ( endOfSection - startOfSection ) );

		return(
			reReplaceFirst( sectionContent, "JVM Stack Trace\s+-+" )
		);

	}


	// I return the portion of the given normalized data that houses the running requests.
	private string function extractRunningRequestsSection( required string content ) {

		var startOfSection = find( "Running Requests (Full Details)", content );

		var sectionContent = mid( content, startOfSection, len( content ) );

		return( sectionContent );

	}


	// I return the report for the active ColdFusion threads.
	private query function getColdFusionThreadsReport() {

		var report = queryNew( "jvmID, threadID, isCFThread, hashcode, priority, stackTrace" );

		for ( var coldfusionThread in getColdFusionThreads() ) {

			queryAddRow( report, 1 );

			report.jvmID[ report.recordCount ] = javaCast( "string", coldfusionThread.jvmID );
			report.threadID[ report.recordCount ] = javaCast( "string", coldfusionThread.threadID );
			report.isCFThread[ report.recordCount ] = javaCast( "boolean", coldfusionThread.isCFThread );
			report.hashcode[ report.recordCount ] = javaCast( "string", coldfusionThread.hashcode );
			report.priority[ report.recordCount ] = javaCast( "string", coldfusionThread.priority );
			report.stackTrace[ report.recordCount ] = coldfusionThread.stackTrace;

		}

		return( report );

	}


	// I return the Java thread with the given ID. Or, void if not found.
	private any function getJavaThreadByID( required string threadID ) {

		for ( var javaThread in javaThreads ) {

			if ( javaThread.threadID == threadID ) {

				return( javaThread );

			}

		}

	}


	// I return the report for the running requests.
	private query function getRunningRequestsReport() {

		var report = queryNew( "requestID, requestUrl, status, startedAt, startedAtDate, threadID, ipAddress, method, duration, usedMemoryPercent, maxMemoryKB, usedMemoryKB, totalMemoryKB, freeMemoryKB, queryString, statusCode, cpuTime, jdbcQueriesRun, jdbcTotalTime, jdbcTotalExecutionTime, jdbcTotalRowCount, amfRquest, bytesSent, timeToFirstByte, timeToLastByte, timeToStreamOpen, timeToStreamClose, userAgent, thread" );

		for ( var runningRequest in runningRequests ) {

			queryAddRow( report, 1 );

			report.requestID[ report.recordCount ] = javaCast( "string", runningRequest.requestID );
			report.requestUrl[ report.recordCount ] = javaCast( "string", runningRequest.requestUrl );
			report.status[ report.recordCount ] = javaCast( "string", runningRequest.status );
			report.startedAt[ report.recordCount ] = javaCast( "long", runningRequest.startedAt );
			report.startedAtDate[ report.recordCount ] = parseDateTime( runningRequest.startedAtDate );
			report.threadID[ report.recordCount ] = javaCast( "string", runningRequest.threadID );
			report.ipAddress[ report.recordCount ] = javaCast( "string", runningRequest.ipAddress );
			report.method[ report.recordCount ] = javaCast( "string", runningRequest.method );
			report.duration[ report.recordCount ] = javaCast( "long", runningRequest.duration );
			report.usedMemoryPercent[ report.recordCount ] = javaCast( "string", runningRequest.usedMemoryPercent );
			report.maxMemoryKB[ report.recordCount ] = javaCast( "long", runningRequest.maxMemoryKB );
			report.usedMemoryKB[ report.recordCount ] = javaCast( "long", runningRequest.usedMemoryKB );
			report.totalMemoryKB[ report.recordCount ] = javaCast( "long", runningRequest.totalMemoryKB );
			report.freeMemoryKB[ report.recordCount ] = javaCast( "long", runningRequest.freeMemoryKB );
			report.queryString[ report.recordCount ] = javaCast( "string", runningRequest.queryString );
			report.statusCode[ report.recordCount ] = javaCast( "string", runningRequest.statusCode );
			report.cpuTime[ report.recordCount ] = javaCast( "long", runningRequest.cpuTime );
			report.jdbcQueriesRun[ report.recordCount ] = javaCast( "int", runningRequest.jdbcQueriesRun );
			report.jdbcTotalTime[ report.recordCount ] = javaCast( "int", runningRequest.jdbcTotalTime );
			report.jdbcTotalExecutionTime[ report.recordCount ] = javaCast( "int", runningRequest.jdbcTotalExecutionTime );
			report.jdbcTotalRowCount[ report.recordCount ] = javaCast( "int", runningRequest.jdbcTotalRowCount );
			report.amfRquest[ report.recordCount ] = javaCast( "string", runningRequest.amfRquest );
			report.bytesSent[ report.recordCount ] = javaCast( "long", runningRequest.bytesSent );
			report.timeToFirstByte[ report.recordCount ] = javaCast( "long", runningRequest.timeToFirstByte );
			report.timeToLastByte[ report.recordCount ] = javaCast( "long", runningRequest.timeToLastByte );
			report.timeToStreamOpen[ report.recordCount ] = javaCast( "long", runningRequest.timeToStreamOpen );
			report.timeToStreamClose[ report.recordCount ] = javaCast( "string", runningRequest.timeToStreamClose );
			report.userAgent[ report.recordCount ] = javaCast( "string", runningRequest.userAgent );

			// Add the related thread.
			var relatedThread = getJavaThreadByID( runningRequest.threadID );

			if ( structKeyExists( local, "relatedThread" ) ) {

				report.thread[ report.recordCount ] = relatedThread;

			}

		}

		// Order by the longest running requests first.
		report = new Query(
			report = report,
			dbtype = "query",
			name = "orderedReport",
			sql = "SELECT * FROM report ORDER BY duration DESC"
		)
		.execute()
		.getResult()
		;

		return( report );

	}


	// I determine if the given Java thread represents a CFThread.
	private boolean function isActiveColdFusionThread( required struct javaThread ) {

		return(
			javaThread.isCFThread &&
			arrayLen( javaThread.stackTrace ) && 
			! findNoCase( "java.lang.Object.wait", javaThread.stackTrace[ 1 ] )
		);

	}


	// I normalize the email content, removing whitespace oddities caused by email formatting.
	private string function normalizeEmailContent( required string emailContent ) {

		var content = trim( emailContent );

		var spaceTab = ( chr( 32 ) & chr( 9 ) );

		// Standardize the linebreaks.
		content = reReplaceAll( content, "(\r\n?|\n)", chr( 10 ) );

		// Strip out all the leading / trailgin white space on each line.
		content = reReplaceAll( content, "(?m)^[#spaceTab#]+|[#spaceTab#]+$" );

		// Make sure all URLs on the line they are supposed to be on - some URLs wrap to the next line.
		content = reReplaceAll( content, "\n(http)", " $1" );

		// Fix line breaks in some of the stack-trace items.
		content = reReplaceAll( content, "\[Native\s+Method\]", "[Native Method]" );

		// Remove any line breaks from the Fusion Reactor thread IDs.
		content = reReplaceAll( content, "(FusionReactor Web Server \([^\n)]+)\n([^)\n]+\))", "$1 $2" );

		// Remove any line breaks from user-agent strings.
		content = reReplaceAll( content, "(User Agent:)([^\n]+)(?:\n)([^\s][^\n]*)", "$1$2 $3" );

		// Remove streamin-data references. These are only going to complicate parsing.
		content = reReplaceAll( content, "\[Note: Data is still streaming\]" );

		return( content );

	}


	// I parse a single running-request content item into a key-value collection.
	private struct function parseRunningRequest( required string content ) {

		var requestProperties = {};

		// Change the keys into something more appropriate for parsing and for data structures. 
		// Each of the values preceding the ":" will become a key in the resultant collection.
		content = replace( content, "Request ID", "requestID", "one" );
		content = replace( content, "Request URL", "requestUrl", "one" );
		content = replace( content, "Status", "status", "one" );
		content = replace( content, "Started (Milliseconds)", "startedAt", "one" );
		content = replace( content, "Started (Date/Time)", "startedAtDate", "one" );
		content = replace( content, "Thread ID", "threadID", "one" );
		content = replace( content, "Client IP Address", "ipAddress", "one" );
		content = replace( content, "Request Method", "method", "one" );
		content = replace( content, "Execution Time (ms)", "duration", "one" );
		content = replace( content, "Used Memory (percentage)", "usedMemoryPercent", "one" );
		content = replace( content, "Max Memory (KB)", "maxMemoryKB", "one" );
		content = replace( content, "Used Memory (KB)", "usedMemoryKB", "one" );
		content = replace( content, "Total Memory (KB)", "totalMemoryKB", "one" );
		content = replace( content, "Free Memory (KB)", "freeMemoryKB", "one" );
		content = replace( content, "Query String", "queryString", "one" );
		content = replace( content, "Return Status Code", "statusCode", "one" );
		content = replace( content, "CPU Time (ms)", "cpuTime", "one" );
		content = replace( content, "JDBC Queries Run", "jdbcQueriesRun", "one" );
		content = replace( content, "JDBC Total Time", "jdbcTotalTime", "one" );
		content = replace( content, "JDBC Total Execution Time", "jdbcTotalExecutionTime", "one" );
		content = replace( content, "JDBC Total Row Count", "jdbcTotalRowCount", "one" );
		content = replace( content, "AMF Request", "amfRquest", "one" );
		content = replace( content, "Bytes Sent", "bytesSent", "one" );
		content = replace( content, "Time to First Byte (ms)", "timeToFirstByte", "one" );
		content = replace( content, "Time to Last Byte (ms)", "timeToLastByte", "one" );
		content = replace( content, "Time to Stream Open (ms)", "timeToStreamOpen", "one" );
		content = replace( content, "Time to Stream Close (ms)", "timeToStreamClose", "one" );
		content = replace( content, "User Agent", "userAgent", "one" );

		// Get the individual lines of content.
		var parts = reSplit( content, "\n+" );

		// For each line, break up the key/value pair based on the first ":" instance.
		for ( var part in parts ) {

			var key = trim( listFirst( part, ":" ) );
			var value = trim( listRest( part, ":" ) );

			requestProperties[ key ] = value;

		}
		
		return( requestProperties );

	}


	// I parse the running requests into an array of data structures.
	private array function parseRunningRequests( required string content ) {

		var runningRequests = [];

		var sectionContent = extractRunningRequestsSection( content );

		var parts = reGather( sectionContent, "Request ID:((?!Request ID:)[\s\S])+" );

		for ( var part in parts ) {

			arrayAppend( runningRequests, parseRunningRequest( part ) );

		}

		return( runningRequests );

	}


	// I parse a single Java thread content item into a key-value collection.
	private struct function parseJavaThread( required string content ) {

		var javaThreadProperties = {};

		// Each Java thread is composed of two different parts - the thread information and 
		// the actual stack trace information. The two sections are separated by a double line-
		// break.
		// --
		// NOTE: Not all threads will report a stack trace.
		var doubleLineBreakIndex = reFind( "\n{2}", content );

		// If the stack-trace doesn't have any content, we'll only have key-value pairs.
		if ( doubleLineBreakIndex ) {

			var propertyContent = trim( mid( content, 1, doubleLineBreakIndex ) );
			var stacktraceContent = trim( mid( content, doubleLineBreakIndex, len( content ) ) );

		} else {

			var propertyContent = content;
			var stacktraceContent = "";
		}
	 
		// Change the keys in the property content into something more appropriate for parsing 
		// and for data structures. Each of the values preceding the ":" will become a key in
		// the resultant collection.
		propertyContent = replace( propertyContent, "JVM ID", "jvmID", "one" );
		propertyContent = replace( propertyContent, "Thread ID", "threadID", "one" );
		propertyContent = replace( propertyContent, "Priority", "priority", "one" );
		propertyContent = replace( propertyContent, "Hashcode", "hashcode", "one" );

		// Get the individual lines of content.
		var parts = reSplit( propertyContent, "\n+" );

		// For each line, break up the key/value pair based on the first ":" instance.
		for ( var part in parts ) {

			var key = trim( listFirst( part, ":" ) );
			var value = trim( listRest( part, ":" ) );

			javaThreadProperties[ key ] = value;

		}

		// Add a flag to differentiate ColdFusion threads (initiated via the CFThread tag) from
		// the other Java threads that are running the entire J2EE application.
		javaThreadProperties[ "isCFThread" ] = !! reFind( "^cfthread-", javaThreadProperties.threadID );

		// Now, add the raw stack trace data, if we have any.
		if ( len( stacktraceContent ) ) {

			javaThreadProperties[ "stacktrace" ] = reSplit( stacktraceContent, "\n+" );

		} else {

			javaThreadProperties[ "stacktrace" ] = [];
			
		}
		
		return( javaThreadProperties );

	}


	// I parse the Java threads into an array of data structures.
	private array function parseJavaThreads( required string content ) {

		var javaThreads = [];

		var sectionContent = extractJavaThreadsSection( content );

		var parts = reGather( sectionContent, "JVM ID:((?!---------)[\s\S])+" );

		for ( var part in parts ) {

			arrayAppend( javaThreads, parseJavaThread( part ) );

		}

		return( javaThreads );

	}


	// I gather all matches for the given pattern found within the given content. This
	// is basically doing what reMatch() does; however, it is faster and more memory 
	// efficient (reMatch() can cause stack-overflow errors on large content).
	private array function reGather(
		required string content,
		required string pattern,
		boolean trimMatch = true
		) {

		var matches = [];

		var matcher = createObject( "java", "java.util.regex.Pattern" )
			.compile( javaCast( "string", pattern ) )
			.matcher( javaCast( "string", content ) )
		;

		while ( matcher.find() ) {

			arrayAppend( 
				matches,
				( trimMatch ? trim( matcher.group() ) : matcher.group() )
			);

		}

		return( matches );

	}


	// I provide a wrapper to String.replaceAll() that doesn't require  java-casting.
	private string function reReplaceAll(
		required string content,
		required string pattern,
		string replacement = ""
		) {

		return(
			javaCast( "string", content ).replaceAll(
				javaCast( "string", pattern ),
				javaCast( "string", replacement )
			)
		);

	}


	// I provide a wrapper to String.replaceFirst() that doesn't require  java-casting.
	private string function reReplaceFirst(
		required string content,
		required string pattern,
		string replacement = ""
		) {

		return(
			javaCast( "string", content ).replaceFirst(
				javaCast( "string", pattern ),
				javaCast( "string", replacement )
			)
		);

	}


	// I split the given content on the given regular expression pattern.
	private array function reSplit(
		required string content,
		required string pattern
		) {

		var parts = javaCast( "string", content ).split( javaCast( "string", pattern ) );

		return( toColdFusionArray( parts ) );

	}


	// I convert the given Java array into a ColdFusion array.
	private array function toColdFusionArray( required any javaArray ) {

		var arrayLength = arrayLen( javaArray );
		var array = [];

		arrayResize( array, arrayLength );

		for ( var i = 1 ; i <= arrayLength ; i++ ) {

			array[ i ] = javaArray[ i ];

		}

		return( array );

	}

}