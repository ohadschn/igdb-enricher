namespace GameEnricher;

public sealed class EnricherOptions
{
    public required FileInfo Input { get; init; }
    public required FileInfo Output { get; init; }
    public required Uri Endpoint { get; init; }
    public required string ApiKey { get; init; }
    public required string Model { get; init; }
}