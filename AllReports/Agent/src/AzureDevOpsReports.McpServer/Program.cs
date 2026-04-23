using AzureDevOpsReports.McpServer.Database;
using AzureDevOpsReports.McpServer.Tools;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

var builder = Host.CreateApplicationBuilder(args);

builder.Logging.ClearProviders();
builder.Logging.AddConsole(o => o.LogToStandardErrorThreshold = LogLevel.Trace);

var connectionString =
    Environment.GetEnvironmentVariable("AZDO_REPORTS_CONNECTION_STRING")
    ?? builder.Configuration["ConnectionStrings:AzureDevOpsReports"]
    ?? throw new InvalidOperationException(
        "Missing connection string. Set AZDO_REPORTS_CONNECTION_STRING environment variable or ConnectionStrings:AzureDevOpsReports configuration value.");

builder.Services.AddSingleton(new SqlConnectionFactory(connectionString));
builder.Services.AddSingleton<SqlQueryExecutor>();
builder.Services.AddSingleton<ReadOnlySqlValidator>();

builder.Services
    .AddMcpServer()
    .WithStdioServerTransport()
    .WithTools<ReportTools>();

await builder.Build().RunAsync();
