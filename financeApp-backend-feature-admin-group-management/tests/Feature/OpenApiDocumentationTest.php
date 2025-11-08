<?php

namespace Tests\Feature;

use Tests\TestCase;

class OpenApiDocumentationTest extends TestCase
{
    /**
     * Test that OpenAPI documentation can be generated
     */
    public function test_openapi_documentation_generation(): void
    {
        // Check if the openapi:generate command exists
        $this->artisan('list')
            ->assertExitCode(0);

        // Try to generate the documentation
        $this->artisan('openapi:generate')
            ->assertExitCode(0);

        // Check that the JSON file was created
        $jsonPath = storage_path('api-docs/api-docs.json');
        $this->assertFileExists($jsonPath, 'OpenAPI JSON documentation file should exist');

        // Check that the YAML file was created
        $yamlPath = storage_path('api-docs/api-docs.yaml');
        $this->assertFileExists($yamlPath, 'OpenAPI YAML documentation file should exist');
    }

    /**
     * Test that generated OpenAPI specification is valid
     */
    public function test_openapi_specification_validation(): void
    {
        // Generate documentation first
        $this->artisan('openapi:generate')->assertExitCode(0);

        $jsonPath = storage_path('api-docs/api-docs.json');
        $this->assertFileExists($jsonPath);

        // Read and parse the JSON
        $content = file_get_contents($jsonPath);
        $this->assertNotEmpty($content, 'OpenAPI JSON file should not be empty');

        $spec = json_decode($content, true);
        $this->assertIsArray($spec, 'OpenAPI JSON should be valid JSON');

        // Validate required OpenAPI 3.0 fields
        $this->assertArrayHasKey('openapi', $spec, 'OpenAPI spec must have "openapi" field');
        $this->assertArrayHasKey('info', $spec, 'OpenAPI spec must have "info" field');
        $this->assertArrayHasKey('paths', $spec, 'OpenAPI spec must have "paths" field');

        // Validate OpenAPI version
        $this->assertStringStartsWith('3.0', $spec['openapi'], 'OpenAPI version should be 3.0.x');

        // Validate info section
        $this->assertArrayHasKey('title', $spec['info'], 'Info section must have "title"');
        $this->assertArrayHasKey('version', $spec['info'], 'Info section must have "version"');

        // Validate that we have paths defined
        $this->assertNotEmpty($spec['paths'], 'OpenAPI spec should have at least one path defined');

        // Validate security schemes
        if (isset($spec['components']['securitySchemes'])) {
            $this->assertArrayHasKey('sanctum', $spec['components']['securitySchemes'], 
                'Should have Sanctum security scheme defined');
        }
    }

    /**
     * Test that key API endpoints are documented
     */
    public function test_key_endpoints_are_documented(): void
    {
        // Generate documentation first
        $this->artisan('openapi:generate')->assertExitCode(0);

        $jsonPath = storage_path('api-docs/api-docs.json');
        $spec = json_decode(file_get_contents($jsonPath), true);

        // Check for key authentication endpoints
        $expectedEndpoints = [
            '/api/v1/auth/register',
            '/api/v1/auth/login',
            '/api/v1/auth/logout',
            '/api/v1/expenses',
            '/api/v1/transfers',
            '/api/v1/incoming',
            '/api/v1/fund-box',
            '/api/v1/profile',
        ];

        foreach ($expectedEndpoints as $endpoint) {
            $this->assertArrayHasKey($endpoint, $spec['paths'], 
                "Endpoint {$endpoint} should be documented");
        }
    }

    /**
     * Test that Swagger UI route is accessible
     */
    public function test_swagger_ui_accessibility(): void
    {
        // Generate documentation first
        $this->artisan('openapi:generate')->assertExitCode(0);
        
        // Test that the documentation UI route exists
        $response = $this->get('/api/documentation');
        
        // Should return 200 with the Swagger UI HTML
        $response->assertStatus(200);
        $response->assertSee('swagger-ui', false);
        
        // Test that we can read the JSON file directly
        $jsonPath = storage_path('api-docs/api-docs.json');
        $this->assertFileExists($jsonPath);
        
        $spec = json_decode(file_get_contents($jsonPath), true);
        $this->assertIsArray($spec);
        $this->assertArrayHasKey('openapi', $spec);
        $this->assertArrayHasKey('info', $spec);
        $this->assertArrayHasKey('paths', $spec);
    }

    /**
     * Test OpenAPI specification structure
     */
    public function test_openapi_specification_structure(): void
    {
        $this->artisan('openapi:generate')->assertExitCode(0);

        $jsonPath = storage_path('api-docs/api-docs.json');
        $spec = json_decode(file_get_contents($jsonPath), true);

        // Validate servers configuration
        if (isset($spec['servers'])) {
            $this->assertIsArray($spec['servers'], 'Servers should be an array');
            $this->assertNotEmpty($spec['servers'], 'Should have at least one server defined');
        }

        // Validate tags
        if (isset($spec['tags'])) {
            $this->assertIsArray($spec['tags'], 'Tags should be an array');
            $this->assertNotEmpty($spec['tags'], 'Should have tags defined for organization');
        }

        // Validate components/schemas
        if (isset($spec['components']['schemas'])) {
            $this->assertIsArray($spec['components']['schemas'], 'Schemas should be an array');
            
            // Check for common schemas
            $expectedSchemas = ['User', 'Expense', 'Transfer', 'Incoming', 'ErrorResponse'];
            foreach ($expectedSchemas as $schema) {
                $this->assertArrayHasKey($schema, $spec['components']['schemas'], 
                    "Schema {$schema} should be defined");
            }
        }
    }

    /**
     * Test that documentation includes proper HTTP methods
     */
    public function test_endpoints_have_proper_http_methods(): void
    {
        $this->artisan('openapi:generate')->assertExitCode(0);

        $jsonPath = storage_path('api-docs/api-docs.json');
        $spec = json_decode(file_get_contents($jsonPath), true);

        // Check that endpoints have proper HTTP methods
        foreach ($spec['paths'] as $path => $methods) {
            $this->assertIsArray($methods, "Path {$path} should have methods defined");
            
            // Each method should have required fields
            foreach ($methods as $method => $details) {
                if (in_array($method, ['get', 'post', 'put', 'delete', 'patch'])) {
                    $this->assertArrayHasKey('responses', $details, 
                        "Method {$method} on {$path} should have responses defined");
                    $this->assertArrayHasKey('summary', $details, 
                        "Method {$method} on {$path} should have a summary");
                }
            }
        }
    }

    /**
     * Clean up generated documentation files after tests
     */
    protected function tearDown(): void
    {
        parent::tearDown();
        
        // Clean up generated files
        $jsonPath = storage_path('api-docs/api-docs.json');
        $yamlPath = storage_path('api-docs/api-docs.yaml');
        
        if (file_exists($jsonPath)) {
            unlink($jsonPath);
        }
        
        if (file_exists($yamlPath)) {
            unlink($yamlPath);
        }
        
        // Remove directory if empty
        $dir = storage_path('api-docs');
        if (is_dir($dir) && count(scandir($dir)) == 2) {
            rmdir($dir);
        }
    }
}
