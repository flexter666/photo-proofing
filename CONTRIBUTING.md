# Contributing to Photo Proofing Portal

Thank you for your interest in contributing to the Photo Proofing Portal! This document provides guidelines and information for contributors.

## Development Setup

1. **Fork and clone the repository**
   ```bash
   git clone https://github.com/your-username/photo-proofing.git
   cd photo-proofing
   ```

2. **Set up development environment**
   ```bash
   cp .env.example .env
   make dev
   ```

3. **Install pre-commit hooks** (optional but recommended)
   ```bash
   pip install pre-commit
   pre-commit install
   ```

## Development Workflow

### Making Changes

1. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**
   - Follow the existing code style
   - Add tests for new functionality
   - Update documentation as needed

3. **Run tests and checks**
   ```bash
   make test        # Run tests
   make lint        # Check code style
   make fmt         # Format code
   ```

4. **Commit your changes**
   ```bash
   git add .
   git commit -m "feat: add your feature description"
   ```

### Commit Message Format

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

- `feat:` New features
- `fix:` Bug fixes
- `docs:` Documentation changes
- `style:` Code style changes (formatting, etc.)
- `refactor:` Code refactoring
- `test:` Adding or updating tests
- `chore:` Maintenance tasks

Examples:
- `feat: add user authentication system`
- `fix: resolve database connection timeout`
- `docs: update API documentation`

### Pull Request Process

1. **Ensure your branch is up to date**
   ```bash
   git fetch origin
   git rebase origin/main
   ```

2. **Push your branch**
   ```bash
   git push origin feature/your-feature-name
   ```

3. **Create a Pull Request**
   - Use a descriptive title
   - Provide a detailed description of changes
   - Link any related issues
   - Ensure all CI checks pass

4. **Code Review**
   - Address feedback from reviewers
   - Update your branch as needed
   - Maintain a clean commit history

## Code Style Guidelines

### Python Code Style

- Follow PEP 8 with 88-character line length
- Use type hints for function parameters and return values
- Write docstrings for all public functions and classes
- Use meaningful variable and function names

### FastAPI Conventions

- Use dependency injection for database sessions
- Implement proper error handling with HTTP status codes
- Document endpoints with proper descriptions and examples
- Use Pydantic models for request/response validation

### Database

- Always use Alembic migrations for schema changes
- Write both upgrade and downgrade migrations
- Test migrations on sample data
- Follow naming conventions for tables and columns

## Testing

### Test Types

1. **Unit Tests**
   - Test individual functions and classes
   - Use mocking for external dependencies
   - Aim for high coverage of business logic

2. **Integration Tests**
   - Test API endpoints
   - Test database operations
   - Test service interactions

3. **End-to-End Tests**
   - Test complete user workflows
   - Use test database
   - Verify system behavior

### Testing Guidelines

- Write tests before or alongside new features
- Use descriptive test names
- Test both success and failure cases
- Keep tests independent and isolated

### Running Tests

```bash
make test                 # Run all tests
make test-coverage        # Run tests with coverage report
pytest tests/test_api.py  # Run specific test file
pytest -k "test_auth"     # Run tests matching pattern
```

## Docker Development

### Local Development

- Use `docker-compose.override.yml` for local overrides
- Mount source code for hot reloading
- Use development environment variables

### Building Images

- Test Docker builds locally before pushing
- Ensure multi-stage builds work correctly
- Optimize for image size and build speed

## Documentation

### Code Documentation

- Write clear docstrings for all public APIs
- Include examples in docstrings
- Document complex algorithms and business logic

### API Documentation

- FastAPI automatically generates OpenAPI docs
- Ensure all endpoints have proper descriptions
- Include request/response examples
- Document error conditions

### README Updates

- Keep installation instructions current
- Update examples when APIs change
- Document new features and breaking changes

## Security Guidelines

### Environment Variables

- Never commit secrets to the repository
- Use `.env.example` for documentation
- Validate environment variables at startup

### Dependencies

- Keep dependencies up to date
- Use specific version numbers
- Review security advisories regularly

### API Security

- Implement proper authentication
- Validate all user inputs
- Use HTTPS in production
- Follow OWASP guidelines

## Performance Considerations

### Database

- Use indexes for frequently queried columns
- Avoid N+1 queries
- Use connection pooling
- Consider read replicas for heavy workloads

### API Design

- Implement pagination for large datasets
- Use caching where appropriate
- Optimize database queries
- Consider async operations for I/O

## Issue Reporting

### Bug Reports

Include the following information:
- Operating system and version
- Python version
- Steps to reproduce
- Expected vs actual behavior
- Error messages and logs
- Screenshots if applicable

### Feature Requests

- Describe the use case
- Explain the expected behavior
- Consider implementation complexity
- Discuss alternatives

## Getting Help

- Check existing issues and documentation first
- Ask questions in GitHub Discussions
- Join our community chat (if available)
- Tag maintainers for urgent issues

## Code of Conduct

We are committed to providing a welcoming and inclusive environment for all contributors. Please be respectful in all interactions and follow our community guidelines.

Thank you for contributing to Photo Proofing Portal!