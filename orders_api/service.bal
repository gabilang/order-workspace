import ballerina/http;

import gabilan/order_commons as commons;

configurable int servicePort = ?;

# Order management API backing the order agent and the daily summary automation.
service /orders on new http:Listener(servicePort) {

    # Lists every order known to the system.
    #
    # + return - All stored orders
    resource function get .() returns commons:PurchaseOrder[] {
        return allOrders();
    }

    # Returns the summary figures across every stored order.
    #
    # + return - Counts and combined value of all stored orders
    resource function get summary() returns commons:OrderSummary {
        commons:PurchaseOrder[] storedOrders = allOrders();
        return commons:summarizeOrders(orderList = storedOrders);
    }

    # Returns a single order.
    #
    # + orderId - Identifier of the order to return
    # + return - The matching order, or a not-found response
    resource function get [string orderId]() returns commons:PurchaseOrder|http:NotFound {
        commons:PurchaseOrder? storedOrder = findOrder(orderId = orderId);
        if storedOrder is () {
            return http:NOT_FOUND;
        }
        return storedOrder;
    }

    # Places a new order in the pending state.
    #
    # + orderRequest - Customer name and line items for the new order
    # + return - The created order
    resource function post .(commons:OrderRequest orderRequest) returns commons:PurchaseOrder {
        return addOrder(orderRequest = orderRequest);
    }

    # Moves an order to a new lifecycle state.
    #
    # + orderId - Identifier of the order to update
    # + statusUpdate - The state to move the order to
    # + return - The updated order, or a not-found response
    resource function patch [string orderId]/status(commons:StatusUpdate statusUpdate)
            returns commons:PurchaseOrder|http:NotFound {
        commons:OrderStatus targetStatus = statusUpdate.orderStatus;
        commons:PurchaseOrder? updatedOrder = updateOrderStatus(orderId = orderId, orderStatus = targetStatus);
        if updatedOrder is () {
            return http:NOT_FOUND;
        }
        return updatedOrder;
    }
}
