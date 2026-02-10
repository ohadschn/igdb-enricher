using System.CommandLine;

public static class CommandLineOptions
{
    static public readonly Option<FileInfo> InputOption = new("--input", ["-i"])
    {
        Description = "Input file path",
        Required = true
    };

    static public readonly Option<FileInfo> OutputOption = new("--output", ["-o"])
    {
        Description = "Output file path",
        Required = false
    };

    static public readonly Option<string> OpenAiModelOption = new("--openai-model", ["-m"])
    {
        Description = "OpenAI model to use",
        Required = false,
        DefaultValueFactory = (_) => "gpt-4o-mini"
    };

    static public readonly Option<Uri> OpenAiEndpointOption = new("--openai-endpoint", ["-e"])
    {
        Description = "OpenAI API endpoint",
        Required = false,
        DefaultValueFactory = (_) => new Uri("https://api.openai.com/"),
        CustomParser = result => 
        {
            var token = result.Tokens.SingleOrDefault();
            if (token == null)
            {
                result.AddError("A single argument is required for the OpenAI endpoint");
                return null;
            }

            if (!Uri.TryCreate(token.Value, UriKind.Absolute, out var parsedUri))
            {
                result.AddError("The OpenAI endpoint must be a valid absolute URI");
                return null;
            }
            
            return parsedUri;
        }
    };
}