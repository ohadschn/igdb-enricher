using OpenAI;
using OpenAI.Chat;
using System.ClientModel;

class Program
{
    static async Task Main()
    {
        string endpoint = Environment.GetEnvironmentVariable("OPENAI_ENDPOINT")
         ?? throw new InvalidOperationException("OPENAI_ENDPOINT environment variable is not set.");
        
        string apiKey = Environment.GetEnvironmentVariable("OPENAI_API_KEY")
         ?? throw new InvalidOperationException("OPENAI_API_KEY environment variable is not set.");
        
        string model = Environment.GetEnvironmentVariable("OPENAI_MODEL") ?? "gpt-4o-mini";

        Console.WriteLine($"Endpoint: {endpoint}");
        Console.WriteLine($"Model: {model}");

        Uri endpointUri = new(endpoint);
        ApiKeyCredential apiKeyCredential = new(apiKey);

        ChatClient client = new(
            model: model, 
            credential: apiKeyCredential,
            options: new OpenAIClientOptions()
            {
                Endpoint = endpointUri
            });

        ChatCompletion completion = client.CompleteChat("Say 'this is a test.'");
        Console.WriteLine($"[ASSISTANT]: {completion.Content[0].Text}");
    }
}
