import ballerina/ai;
import ballerinax/ai.openai;

configurable string openAiApiKey = ?;

final ai:ModelProvider orderModel = check new openai:ModelProvider(
    apiKey = openAiApiKey,
    modelType = openai:GPT_4O_MINI
);

final ai:Agent orderAgent = check new (
    systemPrompt = {
        role: "Order Operations Assistant",
        instructions: "You help an operations team reason about customer orders. " +
            "Always answer from the tools rather than from memory. " +
            "Quote order identifiers verbatim and report monetary values with two decimal places. " +
            "Ship an order only when the user explicitly asks you to."
    },
    model = orderModel,
    tools = [listPendingOrders, getOrderDetails, getOrderSummary, shipOrder]
);

// The port is a literal, not a `configurable`: the `ai` OpenAPI extension can only read a literal
// and silently falls back to 9090 for anything else, which would collide with `orders_api`.
listener ai:Listener agentListener = new (listenOn = 9091);

service /orderAgent on agentListener {

    # Answers a natural language question about orders.
    #
    # + chatRequest - Session identifier and the user message
    # + return - The agent reply
    resource function post chat(ai:ChatReqMessage chatRequest) returns ai:ChatRespMessage|error {
        string agentReply = check orderAgent.run(query = chatRequest.message, sessionId = chatRequest.sessionId);
        return {message: agentReply};
    }
}
