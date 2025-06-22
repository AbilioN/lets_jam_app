# Clean Architecture no Flutter

Esta é uma implementação completa da Clean Architecture no Flutter, seguindo os princípios de Robert C. Martin (Uncle Bob).

## Estrutura de Pastas

```
lib/
├── core/                           # Camada Core (Independente de Framework)
│   ├── di/                        # Injeção de Dependência
│   ├── error/                     # Tratamento de Erros
│   ├── network/                   # Verificação de Conectividade
│   └── usecases/                  # Use Cases Base
├── features/                      # Funcionalidades da Aplicação
│   └── auth/                      # Feature de Autenticação
│       ├── data/                  # Camada de Dados
│       │   ├── datasources/       # Fontes de Dados (API, Local)
│       │   ├── models/            # Modelos de Dados
│       │   └── repositories/      # Implementações dos Repositórios
│       ├── domain/                # Camada de Domínio
│       │   ├── entities/          # Entidades de Negócio
│       │   ├── repositories/      # Interfaces dos Repositórios
│       │   └── usecases/          # Casos de Uso
│       └── presentation/          # Camada de Apresentação
│           ├── bloc/              # Gerenciamento de Estado
│           ├── pages/             # Páginas/Telas
│           └── widgets/           # Widgets Reutilizáveis
└── main.dart                      # Ponto de Entrada da Aplicação
```

## Princípios da Clean Architecture

### 1. **Independência de Framework**
- O domínio não depende de nenhum framework externo
- As entidades e casos de uso são independentes do Flutter

### 2. **Testabilidade**
- Cada camada pode ser testada independentemente
- Uso de interfaces para facilitar mocks

### 3. **Independência de UI**
- A lógica de negócio não depende da interface do usuário
- Mudanças na UI não afetam o domínio

### 4. **Independência de Banco de Dados**
- O domínio não conhece detalhes de persistência
- Repositórios abstraem a fonte de dados

### 5. **Independência de Agentes Externos**
- APIs externas são abstraídas através de interfaces
- O domínio não depende de serviços externos

## Camadas da Arquitetura

### 1. **Domain Layer** (Mais Interna)
- **Entities**: Objetos de negócio puros
- **Use Cases**: Regras de negócio da aplicação
- **Repository Interfaces**: Contratos para acesso a dados

### 2. **Data Layer**
- **Models**: Representação dos dados
- **Data Sources**: Implementação de APIs e banco local
- **Repository Implementations**: Implementação dos contratos

### 3. **Presentation Layer** (Mais Externa)
- **BLoC/Cubit**: Gerenciamento de estado
- **Pages**: Telas da aplicação
- **Widgets**: Componentes reutilizáveis

## Dependências Utilizadas

### State Management
- `flutter_bloc`: Gerenciamento de estado reativo

### Dependency Injection
- `get_it`: Container de injeção de dependência
- `injectable`: Geração automática de código para DI

### Network
- `dio`: Cliente HTTP para APIs

### Local Storage
- `shared_preferences`: Armazenamento local simples
- `sqflite`: Banco de dados SQLite

### Utilities
- `equatable`: Comparação de objetos
- `dartz`: Programação funcional (Either, Option)

### Code Generation
- `freezed`: Classes imutáveis
- `json_annotation`: Serialização JSON

## Fluxo de Dados

1. **UI** → **BLoC** → **Use Case** → **Repository** → **Data Source**
2. **Data Source** → **Repository** → **Use Case** → **BLoC** → **UI**

## Benefícios

1. **Manutenibilidade**: Código organizado e fácil de manter
2. **Testabilidade**: Cada camada pode ser testada isoladamente
3. **Escalabilidade**: Fácil adicionar novas features
4. **Flexibilidade**: Mudanças em uma camada não afetam outras
5. **Reutilização**: Lógica de negócio pode ser reutilizada

## Como Adicionar uma Nova Feature

1. **Domain Layer**:
   - Criar entidades em `domain/entities/`
   - Definir interfaces de repositório em `domain/repositories/`
   - Implementar casos de uso em `domain/usecases/`

2. **Data Layer**:
   - Criar modelos em `data/models/`
   - Implementar data sources em `data/datasources/`
   - Implementar repositório em `data/repositories/`

3. **Presentation Layer**:
   - Criar BLoC em `presentation/bloc/`
   - Criar páginas em `presentation/pages/`
   - Criar widgets em `presentation/widgets/`

4. **Dependency Injection**:
   - Registrar dependências em `core/di/injection.dart`

## Exemplo de Uso

```dart
// No BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;

  AuthBloc({required this.loginUseCase}) : super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    final result = await loginUseCase(LoginParams(
      email: event.email,
      password: event.password,
    ));

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }
}
```

Esta estrutura garante que seu código seja limpo, testável e escalável, seguindo os princípios SOLID e as melhores práticas de desenvolvimento de software. 