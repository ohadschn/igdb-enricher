using System.CommandLine;
using System.Diagnostics;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace GameEnricher;

class Program
{
    static async Task Main(string[] args)
    {
        var rootCommand = new RootCommand("Enricher CLI")
        {
            CommandLineOptions.InputOption,
            CommandLineOptions.OutputOption,
            CommandLineOptions.OpenAiEndpointOption,
            CommandLineOptions.OpenAiModelOption
        };

        var parseResult = rootCommand.Parse(args);
        var input = parseResult.GetRequiredValue(CommandLineOptions.InputOption);

        var host = Host.CreateDefaultBuilder()
            .ConfigureServices(services =>
            {
                services.AddSingleton(new EnricherOptions
                {
                    Input = input,
                    Output = parseResult.GetValue(CommandLineOptions.OutputOption) ?? new FileInfo(input.FullName + ".enriched"),
                    Endpoint = parseResult.GetRequiredValue(CommandLineOptions.OpenAiEndpointOption),
                    Model = parseResult.GetRequiredValue(CommandLineOptions.OpenAiModelOption),
                    ApiKey = Util.GetRequiredEnvVar("OPENAI_API_KEY")
                });

                services.AddSingleton<EnricherService>();
            })
            .Build();

        var logger = host.Services.GetRequiredService<ILogger<Program>>();
        logger.LogInformation("{process} started with args: {args}", Process.GetCurrentProcess().ProcessName, string.Join(" ", args));

        var enricher = host.Services.GetRequiredService<EnricherService>();
        await enricher.RunAsync();  
    }
}