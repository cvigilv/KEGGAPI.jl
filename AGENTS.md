# AGENTS.md - Development Guide for KEGGAPI.jl

## Project Overview

KEGGAPI.jl is a Julia package providing programmatic access to the KEGG (Kyoto Encyclopedia of Genes and Genomes) REST API. This package offers functions to retrieve biological data including pathways, compounds, genes, and genomic information.

## Build, Test & Development Commands

### Basic Commands
```bash
# Install package dependencies
julia --project -e "using Pkg; Pkg.instantiate()"

# Run all tests
julia --project -e "using Pkg; Pkg.test()"

# Build package
julia --project -e "using Pkg; Pkg.build()"

# Run single test file
julia --project test/runtests.jl

# Start Julia REPL with project
julia --project

# Generate documentation
julia --project=docs docs/make.jl
```

### Development Setup
```bash
# Activate development environment
julia --project=dev -e "using Pkg; Pkg.develop(PackageSpec(path=pwd()))"

# Add development dependencies
julia --project -e "using Pkg; Pkg.add([\"Test\", \"Runic\", \"Aqua\"])"

# Format code with Runic.jl
julia --project -e "using Runic; Runic.format(\".\")"
```

### Testing Strategy

**Unit Tests (Mocked):** Test wrapper functions without API calls
- `kegg_get()`, `list()`, `info()`, `get_image()`, `conv()`, `find()`, `link()`

**Integration Tests (Real API):** Test core request functionality
- `KEGGAPI.request()` - Must test with actual KEGG API endpoints

**Test Organization:**
- All tests in `test/runtests.jl` 
- Use `@testset` for logical groupings
- Test both success and failure scenarios

## Code Style Guidelines

### Formatting
- **Formatter:** Runic.jl (enforced in CI)
- **Line Length:** No strict limit, but prefer readability
- **Indentation:** 4 spaces (no tabs)

### Imports & Dependencies
```julia
# Qualified imports preferred
import HTTP: get

# Standard library imports
using Test

# Export public API clearly
export @kegg_str, kegg_conv, kegg_ddi, kegg_find, kegg_get, kegg_info, kegg_link, kegg_list, request
```

### Function & Variable Naming
```julia
# Functions: snake_case
function kegg_get(query::Vector{String})
function request_other(url::String)

# Types: PascalCase  
struct RequestError <: Exception
struct KeggTupleList

# Constants: UPPER_SNAKE_CASE
const DEFAULT_CHUNK_SIZE = 10

# Variables: snake_case
chunk_size = 10
response_text = request(url)
```

### Type Annotations
```julia
# Always annotate function parameters
function request(url::String)
function kegg_get(query::Vector{String}, option::String = "")

# Use concrete types in structs
struct RequestError <: Exception
    message::String
end

# Return type annotations for public API
function info(database::String)::String
```

### Documentation
```julia
"""
KEGGAPI.function_name(param1, param2) -> ReturnType

Brief description of what the function does.

Longer description if needed, explaining parameters,
behavior, and any important details.

# Examples
```julia-repl
julia> KEGGAPI.function_name("example")
"result"
```

# Arguments
- `param1::String`: Description of parameter
- `param2::Int`: Description with default value

# Returns
- `String`: Description of return value

# Throws  
- `RequestError`: When API request fails
"""
```

### Error Handling
```julia
# Custom exception types
struct RequestError <: Exception
    message::String
end

# Explicit error throwing
if response.status != 200
    throw(RequestError("Request failed with status $(response.status)"))
end

# Error testing in tests
@test_throws RequestError KEGGAPI.info("invalid_db")
```

### Control Flow & Logic
```julia
# Clear conditional structure
if condition
    action()
elseif other_condition
    other_action()  
else
    default_action()
end

# Prefer early returns to reduce nesting
function process_data(data)
    if isempty(data)
        return nothing
    end
    
    # Main logic here
    return processed_data
end
```

### Comments
```julia
# Use comments to explain WHY, not WHAT
chunk_size = 10  # KEGG API optimal batch size

# Complex logic deserves explanation
# Split queries into chunks to respect API rate limits
for i in 1:query_chunks
    # Process each chunk...
end

# TODO comments for future improvements
# TODO: Add retry logic for failed requests
```

### File Organization
```julia
# Main module (src/KEGGAPI.jl)
module KEGGAPI
import HTTP: get
export functions...
include("Structures.jl")  # Types first
include("Requests.jl")    # Core functionality
include("specialized_functions.jl")
end

# Each file should have focused responsibility
# Structures.jl - Type definitions
# Requests.jl - HTTP request handling  
# Info.jl - Info-related functions
```

### Testing Patterns
```julia
@testset "Function Group" begin
    @testset "specific_function" begin
        # Test successful case
        result = KEGGAPI.specific_function("valid_input")
        @test isa(result, ExpectedType)
        @test length(result) > 0
        
        # Test error case
        @test_throws RequestError KEGGAPI.specific_function("invalid")
    end
end

# Integration test patterns (for KEGGAPI.request only)
@testset "Integration Tests" begin
    @testset "real API calls" begin
        # Test with known working endpoint
        result = KEGGAPI.request("https://rest.kegg.jp/info/kegg")
        @test isa(result, String)
        @test !isempty(result)
    end
end
```

## CI/CD Pipeline

### Current Status
- **Testing:** Julia 1.9 + nightly on Ubuntu
- **Documentation:** Auto-builds and deploys
- **Dependencies:** CompatHelper for automated updates
- **Releases:** TagBot for automated tagging

### Planned Enhancements
- **Formatting:** Runic.jl enforcement (blocks PRs)
- **Extended Testing:** Julia 1.10, nightly
- **Code Quality:** Aqua.jl integration
- **Real API Tests:** For `KEGGAPI.request()` function
- **Semantic Versioning:** Automated enforcement
- **Release Notes:** Automated generation

### Development Workflow
1. Format code with Runic.jl before committing
2. Ensure all tests pass locally
3. Write tests for new functionality
4. Update documentation for public API changes
5. Breaking changes are acceptable with proper notification

## Common Patterns & Examples

### Making API Requests
```julia
# Always use the request() function for HTTP calls
response_text = request("https://rest.kegg.jp/info/$database")

# Handle errors appropriately  
try
    data = request(url)
    return parse_response(data)
catch e
    if e isa RequestError
        # Handle API errors
        return default_value
    else
        rethrow(e)
    end
end
```

### Processing API Responses
```julia
# Split responses consistently
for datum in split(response_text, "\n///\n")
    push!(data, datum)
end

# Clean up response text
response_text2 = replace(response_text, r"\n///([^/]*)$" => "")
```

### Rate Limiting
```julia
# Always include delays between API calls
sleep(0.1)  # 100ms delay between requests
```

This guide ensures consistent, maintainable code that follows Julia best practices while respecting the KEGG API's requirements and limitations.