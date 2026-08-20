import ballerina/http;
import ballerina/io;
import ballerina/log;

import gabilan/order_commons as commons;

configurable string ordersApiUrl = ?;
configurable string orderAgentUrl = ?;

final http:Client ordersApiClient = check new (ordersApiUrl);
final http:Client orderAgentClient = check new (orderAgentUrl, timeout = 120);

# Asks the order agent to narrate the day's order book.
#
# + orderSummary - The figures the agent should explain
# + return - The agent narrative, or an error when the agent is unavailable
isolated function requestNarrative(commons:OrderSummary orderSummary) returns string|error {
    string promptText = string `Summarise today's order book for the operations team. ` +
        string `There are ${orderSummary.totalOrders} orders worth ${orderSummary.totalValue} in total, ` +
        string `and ${orderSummary.pendingOrders} of them are still pending. ` +
        string `List the pending orders and flag the highest value one.`;
    commons:AgentRequest agentRequest = {sessionId: "daily-summary", message: promptText};
    commons:AgentResponse agentResponse = check orderAgentClient->/chat.post(message = agentRequest);
    return agentResponse.message;
}

public function main() returns error? {
    commons:PurchaseOrder[] storedOrders = check ordersApiClient->/.get();
    commons:OrderSummary orderSummary = commons:summarizeOrders(orderList = storedOrders);

    io:println("=== Daily order summary ===");
    io:println(string `Total orders   : ${orderSummary.totalOrders}`);
    io:println(string `Pending orders : ${orderSummary.pendingOrders}`);
    io:println(string `Total value    : ${orderSummary.totalValue}`);

    string|error agentNarrative = requestNarrative(orderSummary = orderSummary);
    if agentNarrative is error {
        log:printWarn("order agent unavailable, reporting figures only", 'error = agentNarrative);
        return;
    }
    io:println("--- Agent narrative ---");
    io:println(agentNarrative);
}
