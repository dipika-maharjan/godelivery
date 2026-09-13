# GoDelivery - Clean Architecture Implementation

## Project Structure

```
lib/
├── main.dart                          # App entry point with routing
├── core/
│   └── service_locator.dart          # Dependency injection setup
├── domain/                            # Business logic layer
│   ├── entities/
│   │   └── user.dart                 # User entity
│   ├── repositories/
│   │   └── auth_repository.dart      # Abstract repository
│   └── usecases/
│       ├── send_otp.dart
│       ├── verify_otp.dart
│       ├── create_account.dart
│       ├── get_current_user.dart
│       └── logout.dart
├── data/                              # Data access layer
│   ├── models/
│   │   └── user_model.dart           # User data model
│   ├── datasources/                  # API/local storage
│   └── repositories/
│       └── auth_repository_impl.dart # Concrete repository
└── presentation/                      # UI layer
    ├── pages/
    │   ├── phone_input_page.dart
    │   ├── otp_verification_page.dart
    │   ├── business_info_page.dart
    │   ├── dashboard_page.dart
    │   └── account_page.dart
    ├── widgets/                       # Reusable UI components
    └── state_management/
        └── auth_provider.dart         # State management
```

## Clean Architecture Layers

### Domain Layer (Business Logic)
- **Entities**: Pure business objects (User)
- **Repositories**: Abstract interfaces for data operations
- **UseCases**: Business logic operations with validation

### Data Layer (Data Access)
- **Models**: Data transfer objects that extend entities
- **DataSources**: API and local storage implementations
- **Repositories**: Concrete implementations of domain repositories

### Presentation Layer (UI)
- **Pages**: Full screens
- **Widgets**: Reusable UI components
- **State Management**: Provider for state management

### Core Layer
- **ServiceLocator**: Dependency injection setup

## Registration Flow

1. **Phone Input Page**: User enters phone number
2. **OTP Verification Page**: User verifies OTP
3. **Business Info Page**: User enters name and business name
4. **Dashboard Page**: Main app screen
5. **Account Page**: User profile and settings

## Dependencies

- **provider**: State management
- **flutter**: UI framework

## Architecture Benefits

✅ **Separation of Concerns**: Each layer has a single responsibility
✅ **Testability**: Easy to unit test each layer independently
✅ **Maintainability**: Clear structure makes code easier to maintain
✅ **Scalability**: Easy to add new features without affecting existing code
✅ **Reusability**: Widgets and logic can be reused across the app
✅ **Dependency Injection**: Loose coupling between components

## Next Steps

1. Implement actual API calls in `data/datasources/`
2. Add local storage for user data using SharedPreferences or Hive
3. Add error handling and validation
4. Create additional widgets for reusable UI components
5. Add logging and analytics
6. Write unit tests for each layer
7. Add more features (shipments, orders, etc.)
