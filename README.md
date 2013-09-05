
# Fusion Reactor Alert

by [Ben Nadel][1] (on [Google+][2])

At work, we use [Fusion Reactor][3] to help monitor the health and performance
of our ColdFusion J2EE applications. When certain application metrics reach a
given threshold, Fusion Reactor sends out an Email Alert with a massive amount
of data including a full stack-trace and a list of all the running requests.

This email alert has been invaluable and I thank my lucky stars that such a 
product even exists! But, I think it could be better; or rather, there are ways
that it could be made more readable. And, to start playing around with some of
these ideas, I thought a great first step would be to parse the raw email 
content into a usable data structure.

The FusionReactorAlert.cfc is a ColdFusion component that takes the raw email
content and provides methods for accessing the running requests, threads, 
CFThreads, and an aggregate report of all the data in structured format. Once
instantiated, the ColdFusion component provides the following public methods:

* getColdFusionThreads() :: array
* getJavaThreads() :: array
* getReport() :: struct
* getRunningRequests() :: array

The "report" is a structure that contains two ColdFusion query objects:

* runningRequests
* coldfusionThreads

By default, the running-requests query is ordered by request duration (DESC);
however, since it's a ColdFusion query, you can run your own query-of-queries
to order it as you see fit. The running-requests query also contains a query 
column, "thread" that embeds the Java thread directly in the request record.

## Caveats

The parsing in this ColdFusion component is based on the way that GMail reports
the "original" email content. I am not sure if this "original" data is 
consistent across various email clients; or, if this is just how you can expect
it in a GMail context.

Furthermore, I built this using Fusion Reactor alerts from a single ColdFusion
application; as such, I am sure there is going to be variation in formatting
that I have not accounted for.


[1]: http://www.bennadel.com
[2]: https://plus.google.com/108976367067760160494?rel=author
[3]: http://www.fusion-reactor.com/