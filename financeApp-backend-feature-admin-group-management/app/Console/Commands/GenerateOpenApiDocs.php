<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\Route;

class GenerateOpenApiDocs extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'openapi:generate';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Generate OpenAPI documentation from routes and annotations';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $this->info('Generating OpenAPI documentation...');

        try {
            // Check if swagger-php is available
            if (class_exists('\OpenApi\Generator')) {
                return $this->generateWithSwaggerPhp();
            }

            // Fallback: Generate basic documentation from routes
            return $this->generateFromRoutes();
        } catch (\Exception $e) {
            $this->error('Error generating documentation: ' . $e->getMessage());
            return 1;
        }
    }

    /**
     * Generate documentation using swagger-php library
     */
    protected function generateWithSwaggerPhp()
    {
        $this->info('Using swagger-php to scan annotations...');

        $openapi = \OpenApi\Generator::scan([base_path('app')]);

        // Create storage directory if it doesn't exist
        $storagePath = storage_path('api-docs');
        if (!file_exists($storagePath)) {
            mkdir($storagePath, 0755, true);
        }

        // Save as JSON
        $jsonPath = $storagePath . '/api-docs.json';
        file_put_contents($jsonPath, $openapi->toJson());
        $this->info("JSON documentation generated: {$jsonPath}");

        // Save as YAML
        $yamlPath = $storagePath . '/api-docs.yaml';
        file_put_contents($yamlPath, $openapi->toYaml());
        $this->info("YAML documentation generated: {$yamlPath}");

        return $this->validateDocumentation($jsonPath);
    }

    /**
     * Generate basic documentation from Laravel routes
     */
    protected function generateFromRoutes()
    {
        $this->info('Generating documentation from Laravel routes...');

        $routes = Route::getRoutes();
        $paths = [];

        foreach ($routes as $route) {
            $uri = $route->uri();
            
            // Only include API routes
            if (!str_starts_with($uri, 'api/')) {
                continue;
            }

            $methods = $route->methods();
            $action = $route->getActionName();

            foreach ($methods as $method) {
                $method = strtolower($method);
                
                if ($method === 'head') {
                    continue;
                }

                $paths['/' . $uri][$method] = [
                    'summary' => $this->generateSummary($uri, $method),
                    'tags' => [$this->getTagFromUri($uri)],
                    'responses' => [
                        '200' => [
                            'description' => 'Successful response'
                        ]
                    ]
                ];

                // Add security for protected routes
                if ($route->middleware() && in_array('auth:sanctum', $route->middleware())) {
                    $paths['/' . $uri][$method]['security'] = [
                        ['sanctum' => []]
                    ];
                }
            }
        }

        $spec = [
            'openapi' => '3.0.0',
            'info' => [
                'title' => 'Finance Backend API',
                'description' => 'RESTful API for finance management application',
                'version' => '1.0.0',
            ],
            'servers' => [
                [
                    'url' => config('app.url') . '/api/v1',
                    'description' => 'API Server'
                ]
            ],
            'paths' => $paths,
            'components' => [
                'securitySchemes' => [
                    'sanctum' => [
                        'type' => 'http',
                        'scheme' => 'bearer',
                        'bearerFormat' => 'JWT',
                        'description' => 'Laravel Sanctum token authentication'
                    ]
                ]
            ]
        ];

        // Create storage directory if it doesn't exist
        $storagePath = storage_path('api-docs');
        if (!file_exists($storagePath)) {
            mkdir($storagePath, 0755, true);
        }

        // Save as JSON
        $jsonPath = $storagePath . '/api-docs.json';
        file_put_contents($jsonPath, json_encode($spec, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES));
        $this->info("JSON documentation generated: {$jsonPath}");

        // Save as YAML (basic conversion)
        $yamlPath = $storagePath . '/api-docs.yaml';
        file_put_contents($yamlPath, $this->jsonToYaml($spec));
        $this->info("YAML documentation generated: {$yamlPath}");

        return $this->validateDocumentation($jsonPath);
    }

    /**
     * Validate the generated documentation
     */
    protected function validateDocumentation($jsonPath)
    {
        $this->info('Validating OpenAPI specification...');
        
        $json = json_decode(file_get_contents($jsonPath), true);
        
        if (!$json) {
            $this->error('Invalid JSON generated');
            return 1;
        }

        // Check required OpenAPI 3.0 fields
        $requiredFields = ['openapi', 'info', 'paths'];
        foreach ($requiredFields as $field) {
            if (!isset($json[$field])) {
                $this->error("Missing required field: {$field}");
                return 1;
            }
        }

        // Validate OpenAPI version
        if (!isset($json['openapi']) || !str_starts_with($json['openapi'], '3.0')) {
            $this->error('Invalid OpenAPI version. Expected 3.0.x');
            return 1;
        }

        $pathCount = count($json['paths']);
        $this->info("✓ OpenAPI specification is valid");
        $this->info("✓ {$pathCount} API endpoints documented");
        $this->info('✓ Documentation generated successfully');

        return 0;
    }

    /**
     * Generate a summary from URI and method
     */
    protected function generateSummary($uri, $method)
    {
        $parts = explode('/', $uri);
        $resource = $parts[count($parts) - 1];
        
        $methodMap = [
            'get' => 'Get',
            'post' => 'Create',
            'put' => 'Update',
            'patch' => 'Update',
            'delete' => 'Delete'
        ];

        return ($methodMap[$method] ?? 'Handle') . ' ' . ucfirst($resource);
    }

    /**
     * Get tag from URI
     */
    protected function getTagFromUri($uri)
    {
        $parts = explode('/', $uri);
        
        if (count($parts) >= 3) {
            return ucfirst($parts[2]);
        }
        
        return 'API';
    }

    /**
     * Convert JSON to YAML (basic implementation)
     */
    protected function jsonToYaml($data, $indent = 0)
    {
        $yaml = '';
        $spaces = str_repeat('  ', $indent);

        foreach ($data as $key => $value) {
            if (is_array($value)) {
                if (array_keys($value) === range(0, count($value) - 1)) {
                    // Indexed array
                    $yaml .= $spaces . $key . ":\n";
                    foreach ($value as $item) {
                        if (is_array($item)) {
                            $yaml .= $spaces . "  -\n";
                            $yaml .= $this->jsonToYaml($item, $indent + 2);
                        } else {
                            $yaml .= $spaces . "  - " . $this->yamlValue($item) . "\n";
                        }
                    }
                } else {
                    // Associative array
                    $yaml .= $spaces . $key . ":\n";
                    $yaml .= $this->jsonToYaml($value, $indent + 1);
                }
            } else {
                $yaml .= $spaces . $key . ': ' . $this->yamlValue($value) . "\n";
            }
        }

        return $yaml;
    }

    /**
     * Format value for YAML
     */
    protected function yamlValue($value)
    {
        if (is_string($value)) {
            return '"' . addslashes($value) . '"';
        }
        
        if (is_bool($value)) {
            return $value ? 'true' : 'false';
        }
        
        if (is_null($value)) {
            return 'null';
        }
        
        return $value;
    }
}
