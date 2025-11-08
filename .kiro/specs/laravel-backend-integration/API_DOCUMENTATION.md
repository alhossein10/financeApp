# Laravel Backend Integration - API Documentation

## Overview

This document provides comprehensive documentation for all public APIs in the Laravel backend integration. Each API is documented with its purpose, parameters, return types, and usage examples.

---

## Core API Client

### ApiClient

**Location:** `lib/core/api/api_client.dart`

**Purpose:** Central HTTP client for all API communication with the Laravel backend.

#### Methods

##### `Future<Response> get(String endpoint, {Map<String, dynamic>? queryParams})`

Performs a GET request to the specified endpoint.

**Parameters:**
- `endpoint` (String): The API endpoint path (e.g., '/api/v1/expenses')
- `queryParams` (Map<String, dynamic>?, optional): Query parameters to append to the URL

**Returns:** `Future<Response>` - The HTTP response

**Throws:** `ApiException` on netwo