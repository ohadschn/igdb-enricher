namespace GameEnricher;

public static class Util
{
    public static string GetRequiredEnvVar(string name)
    {
        return Environment.GetEnvironmentVariable(name) ?? throw new InvalidOperationException($"{name} environment variable is not set.");
    }
}