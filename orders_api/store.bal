import ballerina/time;
import ballerina/uuid;

import gabilan/order_commons as commons;

isolated table<commons:PurchaseOrder> key(orderId) orderTable = table [];

# Accepts a new order and stores it in the pending state.
#
# + orderRequest - Customer name and line items for the new order
# + return - The stored order
isolated function addOrder(commons:OrderRequest orderRequest) returns commons:PurchaseOrder {
    string generatedId = uuid:createRandomUuid();
    string acceptedAt = time:utcToString(time:utcNow());
    commons:PurchaseOrder newOrder = {
        orderId: generatedId,
        customerName: orderRequest.customerName,
        orderItems: orderRequest.orderItems,
        orderStatus: commons:PENDING,
        createdAt: acceptedAt
    };
    lock {
        orderTable.add(newOrder.clone());
    }
    return newOrder;
}

# Looks up a single order by its identifier.
#
# + orderId - Identifier of the order to look up
# + return - The matching order, or `()` when no order carries that identifier
isolated function findOrder(string orderId) returns commons:PurchaseOrder? {
    lock {
        commons:PurchaseOrder? storedOrder = orderTable[orderId];
        if storedOrder is () {
            return ();
        }
        return storedOrder.clone();
    }
}

# Lists every stored order.
#
# + return - All stored orders
isolated function allOrders() returns commons:PurchaseOrder[] {
    lock {
        return orderTable.toArray().clone();
    }
}

# Moves an order to a new lifecycle state.
#
# + orderId - Identifier of the order to update
# + orderStatus - The state to move the order to
# + return - The updated order, or `()` when no order carries that identifier
isolated function updateOrderStatus(string orderId, commons:OrderStatus orderStatus) returns commons:PurchaseOrder? {
    lock {
        commons:PurchaseOrder? storedOrder = orderTable[orderId];
        if storedOrder is () {
            return ();
        }
        storedOrder.orderStatus = orderStatus;
        return storedOrder.clone();
    }
}
