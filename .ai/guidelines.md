# AI Agent Guidelines for Faraday

## Introduction
AI agents must read these guidelines before any work and suggest updates to keep them current. This document focuses on Faraday-specific conventions to ensure consistency and quality in our projects.

## Middleware Patterns
- **Definition**: Middleware in Faraday acts as a bridge between the request and response, allowing for pre-processing or post-processing of data.
- **Implementation**: Use named functions for middleware logic to enhance readability and testability.
- **Order of Execution**: Ensure middleware is applied in the correct sequence, as defined in the application settings.

## Adapter Implementation
- **Purpose**: Adapters are used to translate data formats or protocols, ensuring compatibility between different systems.
- **Structure**: Implement adapters as classes with clearly defined interfaces. Each adapter should handle one specific type of transformation.
- **Testing**: Write unit tests for each adapter to verify that input and output formats align with expectations.

## Testing Approaches
- **Unit Testing**: Focus on testing individual components in isolation. Use mocking to simulate external dependencies.
- **Integration Testing**: Ensure that different components work together as intended. This includes testing middleware and adapters in conjunction.
- **End-to-End Testing**: Validate the entire workflow from start to finish, ensuring that the AI agent behaves as expected in real-world scenarios.

## Code Organization
- **Directory Structure**: Follow the established directory structure in the existing codebase. Place all middleware in the `middleware` directory and adapters in the `adapters` directory.
- **File Naming**: Use descriptive names for files and classes. For middleware, consider using the format `middlewareName.middleware.js`. For adapters, use `adapterName.adapter.js`.
- **Documentation**: Maintain clear documentation for each component, including purpose, usage, and examples. All public methods should be documented with JSDoc comments to facilitate understanding.

## Conclusion
These guidelines are designed to facilitate the effective and efficient use of AI agents in the Faraday project. Regularly review and update these guidelines to reflect changes in best practices and project evolution.