import QtQuick

ApiStrategy {
    property bool isReasoning: false
    // tool_calls arrive across many deltas; accumulate by index until finish_reason: "tool_calls"
    property var pendingToolCalls: ({})

    function buildEndpoint(model: AiModel): string {
        // console.log("[AI] Endpoint: " + model.endpoint);
        return model.endpoint;
    }

    function buildRequestData(model: AiModel, messages, systemPrompt: string, temperature: real, tools: list<var>, filePath: string) {
        let baseData = {
            "model": model.model,
            "messages": [
                {role: "system", content: systemPrompt},
                ...messages.map(message => {
                    // Tool response: must be role "tool" with tool_call_id linking back to the assistant call
                    if (message.functionResponse?.length > 0 && message.functionName?.length > 0) {
                        return {
                            "role": "tool",
                            "name": message.functionName,
                            "content": message.functionResponse,
                            "tool_call_id": message.functionCall?.id,
                        };
                    }
                    // Assistant turn that emitted a tool call: must include tool_calls array so the tool response can reference it
                    if (message.role === "assistant" && message.functionCall && typeof message.functionCall === "object" && message.functionCall.name) {
                        return {
                            "role": "assistant",
                            "content": message.rawContent,
                            "tool_calls": [{
                                "id": message.functionCall.id,
                                "type": "function",
                                "function": {
                                    "name": message.functionCall.name,
                                    "arguments": JSON.stringify(message.functionCall.args ?? {}),
                                }
                            }],
                        };
                    }
                    return {
                        "role": message.role,
                        "content": message.rawContent,
                    }
                }),
            ],
            "stream": true,
            "tools": tools,
            "temperature": temperature,
        };
        return model.extraParams ? Object.assign({}, baseData, model.extraParams) : baseData;
    }

    function buildAuthorizationHeader(apiKeyEnvVarName: string): string {
        return `-H "Authorization: Bearer \$\{${apiKeyEnvVarName}\}"`;
    }

    function parseResponseLine(line, message) {
        // Remove 'data: ' prefix if present and trim whitespace
        let cleanData = line.trim();
        if (cleanData.startsWith("data:")) {
            cleanData = cleanData.slice(5).trim();
        }

        // console.log("[AI] OpenAI: Data:", cleanData);

        // Handle special cases
        if (!cleanData || cleanData.startsWith(":")) return {};
        if (cleanData === "[DONE]") {
            return { finished: true };
        }

        // Real stuff
        try {
            const dataJson = JSON.parse(cleanData);

            // Error response handling
            if (dataJson.error) {
                const errorMsg = `**Error**: ${dataJson.error.message || JSON.stringify(dataJson.error)}`;
                message.rawContent += errorMsg;
                message.content += errorMsg;
                return { finished: true };
            }

            const delta = dataJson.choices?.[0]?.delta;
            const finishReason = dataJson.choices?.[0]?.finish_reason;

            // Accumulate streamed tool_call fragments by index. OpenAI splits function.arguments across many deltas.
            if (delta?.tool_calls) {
                for (const tc of delta.tool_calls) {
                    const idx = tc.index ?? 0;
                    if (!pendingToolCalls[idx]) pendingToolCalls[idx] = { id: "", name: "", argsBuffer: "" };
                    if (tc.id) pendingToolCalls[idx].id = tc.id;
                    if (tc.function?.name) pendingToolCalls[idx].name = tc.function.name;
                    if (typeof tc.function?.arguments === "string") pendingToolCalls[idx].argsBuffer += tc.function.arguments;
                }
                return {};
            }

            // When the server signals the assistant chose tool calls, parse the accumulated args and emit.
            if (finishReason === "tool_calls" && Object.keys(pendingToolCalls).length > 0) {
                const tc = pendingToolCalls[0] ?? pendingToolCalls[Object.keys(pendingToolCalls)[0]];
                let args = {};
                try { args = JSON.parse(tc.argsBuffer || "{}"); } catch (e) {
                    console.log("[AI] OpenAI: Could not parse tool_call arguments:", e, "raw:", tc.argsBuffer);
                }
                const annotation = `\n\n[[ Function: ${tc.name}(${JSON.stringify(args, null, 2)}) ]]\n`;
                message.rawContent += annotation;
                message.content += annotation;
                message.functionName = tc.name;
                message.functionCall = { name: tc.name, args: args, id: tc.id };
                pendingToolCalls = ({});
                return { functionCall: { name: tc.name, args: args, id: tc.id } };
            }

            let newContent = "";

            const responseContent = delta?.content || dataJson.message?.content;
            const responseReasoning = delta?.reasoning || delta?.reasoning_content;

            if (responseContent && responseContent.length > 0) {
                if (isReasoning) {
                    isReasoning = false;
                    const endBlock = "\n\n</think>\n\n";
                    message.content += endBlock;
                    message.rawContent += endBlock;
                }
                newContent = responseContent;
            } else if (responseReasoning && responseReasoning.length > 0) {
                if (!isReasoning) {
                    isReasoning = true;
                    const startBlock = "\n\n<think>\n\n";
                    message.rawContent += startBlock;
                    message.content += startBlock;
                }
                newContent = responseReasoning;
            }

            message.content += newContent;
            message.rawContent += newContent;

            // Usage metadata
            if (dataJson.usage) {
                return {
                    tokenUsage: {
                        input: dataJson.usage.prompt_tokens ?? -1,
                        output: dataJson.usage.completion_tokens ?? -1,
                        total: dataJson.usage.total_tokens ?? -1
                    }
                };
            }

            if (dataJson.done) {
                return { finished: true };
            }

        } catch (e) {
            console.log("[AI] OpenAI: Could not parse line: ", e);
            message.rawContent += line;
            message.content += line;
        }

        return {};
    }

    function onRequestFinished(message) {
        // OpenAI format doesn't need special finish handling
        return {};
    }

    function reset() {
        isReasoning = false;
        pendingToolCalls = ({});
    }

}
