# Calculates the total value of a single order.
#
# + purchaseOrder - The order to be valued
# + return - Sum of quantity times unit price across all line items
public isolated function calculateOrderTotal(PurchaseOrder purchaseOrder) returns decimal {
    decimal runningTotal = 0;
    OrderItem[] orderItems = purchaseOrder.orderItems;
    foreach OrderItem eachItem in orderItems {
        runningTotal += <decimal>eachItem.itemQuantity * eachItem.itemPrice;
    }
    return runningTotal;
}

# Aggregates a set of orders into a summary.
#
# + orderList - The orders to be aggregated
# + return - Counts and combined value across the given orders
public isolated function summarizeOrders(PurchaseOrder[] orderList) returns OrderSummary {
    int pendingCount = 0;
    decimal combinedValue = 0;
    foreach PurchaseOrder eachOrder in orderList {
        if eachOrder.orderStatus == PENDING {
            pendingCount += 1;
        }
        combinedValue += calculateOrderTotal(purchaseOrder = eachOrder);
    }
    return {
        totalOrders: orderList.length(),
        pendingOrders: pendingCount,
        totalValue: combinedValue
    };
}
