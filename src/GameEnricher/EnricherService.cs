using System.ClientModel;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using OpenAI;
using OpenAI.Chat;

namespace GameEnricher;

public sealed class EnricherService(EnricherOptions options, ILogger<EnricherService> logger, IHostApplicationLifetime lifetime)
{
    private readonly EnricherOptions _options = options;
    private readonly ILogger<EnricherService> _logger = logger;
    private readonly IHostApplicationLifetime _lifetime = lifetime;

    public async Task RunAsync()
    {
        var client = new ChatClient(
            model: _options.Model, 
            credential: new ApiKeyCredential(_options.ApiKey),
            options: new OpenAIClientOptions()
            {
                Endpoint = _options.Endpoint
            });

        ChatCompletion completion = await client.CompleteChatAsync(
            [new UserChatMessage("Say 'this is a test.'")], 
            cancellationToken: _lifetime.ApplicationStopping);
            
        _logger.LogInformation("[ASSISTANT]: {Content}", completion.Content[0].Text);
    }
}