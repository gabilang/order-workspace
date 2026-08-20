# Lifecycle states an order moves through.
public enum OrderStatus {
    PENDING,
    SHIPPED,
    CANCELLED
}

# A single line item within an order.
public type OrderItem record {|
    # Stock keeping unit of the product
    string itemCode;
    # Number of units ordered
    int itemQuantity;
    # Unit price of the product
    decimal itemPrice;
|};

# An order accepted by the orders API.
public type PurchaseOrder record {|
    # Unique identifier of the order
    readonly string orderId;
    # Name of the customer who placed the order
    string customerName;
    # Line items belonging to the order
    OrderItem[] orderItems;
    # Current lifecycle state of the order
    OrderStatus orderStatus;
    # Time at which the order was accepted
    string createdAt;
|};

# Payload accepted when placing a new order.
public type OrderRequest record {|
    # Name of the customer placing the order
    string customerName;
    # Line items to be ordered
    OrderItem[] orderItems;
|};

# Aggregated figures over a set of orders.
public type OrderSummary record {|
    # Number of orders considered
    int totalOrders;
    # Number of orders still awaiting shipment
    int pendingOrders;
    # Combined value of all orders considered
    decimal totalValue;
|};

# Request payload accepted by the order agent chat endpoint.
public type AgentRequest record {|
    # Identifier that groups messages into one conversation
    string sessionId;
    # Natural language message sent to the agent
    string message;
|};

# Response payload returned by the order agent chat endpoint.
public type AgentResponse record {|
    # Natural language reply produced by the agent
    string message;
|};

# Payload accepted when moving an order to a new lifecycle state.
public type StatusUpdate record {|
    # The state to move the order to
    OrderStatus orderStatus;
|};
