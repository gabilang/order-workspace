import ballerina/ai;
import ballerina/http;

import gabilan/order_commons as commons;

configurable string ordersApiUrl = ?;

final http:Client ordersApiClient = check new (ordersApiUrl);

# Lists the orders that are still awaiting shipment.
#
# + return - Every order currently in the pending state
@ai:AgentTool
isolated function listPendingOrders() returns commons:PurchaseOrder[]|error {
    commons:PurchaseOrder[] storedOrders = check ordersApiClient->/.get();
    return from commons:PurchaseOrder eachOrder in storedOrders
        where eachOrder.orderStatus == commons:PENDING
        select eachOrder;
}

# Retrieves the full details of one order, including its line items.
#
# + orderId - Identifier of the order to retrieve
# + return - The matching order
@ai:AgentTool
isolated function getOrderDetails(string orderId) returns commons:PurchaseOrder|error {
    commons:PurchaseOrder storedOrder = check ordersApiClient->/[orderId].get();
    return storedOrder;
}

# Returns the aggregated order counts and total order value.
#
# + return - Counts and combined value across every stored order
@ai:AgentTool
isolated function getOrderSummary() returns commons:OrderSummary|error {
    commons:OrderSummary orderSummary = check ordersApiClient->/summary.get();
    return orderSummary;
}

# Marks an order as shipped.
#
# + orderId - Identifier of the order to ship
# + return - The updated order
@ai:AgentTool
isolated function shipOrder(string orderId) returns commons:PurchaseOrder|error {
    commons:StatusUpdate statusUpdate = {orderStatus: commons:SHIPPED};
    commons:PurchaseOrder updatedOrder = check ordersApiClient->/[orderId]/status.patch(message = statusUpdate);
    return updatedOrder;
}
