# Enhanced Community Kudos Contract

A gas-optimized smart contract for sending and managing community kudos on the Stacks blockchain, built with Clarity.

## 🌟 Overview

The Enhanced Community Kudos Contract enables users to send appreciation messages (kudos) to other community members with features like rate limiting, categorization, and comprehensive statistics tracking. This contract is designed for communities, teams, or organizations looking to implement a recognition system on the blockchain.

## ✨ Features

### Core Functionality
- **Send Kudos**: Send appreciation messages to other users with custom messages and categories
- **Rate Limiting**: Prevents spam with one kudo per block per sender-recipient pair
- **Batch Operations**: Send multiple kudos efficiently in a single transaction
- **Message Categorization**: Organize kudos by categories (e.g., "help", "collaboration", "achievement")

### Analytics & Statistics
- **User Statistics**: Track sent/received counts and last activity for each user
- **Kudo Retrieval**: Get kudos by ID, user, or range
- **Activity Tracking**: Monitor community engagement and participation

### Security & Administration
- **Input Validation**: Comprehensive validation for all user inputs
- **Owner Management**: Secure contract ownership with proper validation
- **Error Handling**: Clear error messages and proper error codes

## 📋 Table of Contents

- [Installation](#installation)
- [Usage](#usage)
- [Contract Functions](#contract-functions)
- [Error Codes](#error-codes)
- [Examples](#examples)
- [Development](#development)
- [Testing](#testing)
- [Security](#security)
- [Contributing](#contributing)
- [License](#license)

## 🚀 Installation

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) - Stacks development environment
- [Stacks CLI](https://github.com/blockstack/stacks-blockchain/tree/master/src/stacks-node) - For mainnet/testnet deployment

### Setup
1. Clone the repository:
```bash
git clone https://github.com/your-username/enhanced-community-kudos.git
cd enhanced-community-kudos
```

2. Initialize Clarinet project (if not already done):
```bash
clarinet new kudos-project
cd kudos-project
```

3. Add the contract to your Clarinet.toml:
```toml
[contracts.community-kudos]
path = "contracts/community-kudos.clar"
```

4. Check the contract:
```bash
clarinet check
```

## 💻 Usage

### Basic Kudo Sending
```clarity
;; Send a kudo to another user
(contract-call? .community-kudos send-kudo 'SP1234567890ABCDEF "Great job on the project!" "collaboration")
```

### Batch Sending
```clarity
;; Send kudos to multiple users at once
(contract-call? .community-kudos send-kudos-batch 
  (list 'SP1234567890ABCDEF 'SP0987654321FEDCBA) 
  "Thanks for your contributions!" 
  "team-work")
```

### Retrieving Kudos
```clarity
;; Get a specific kudo by ID
(contract-call? .community-kudos get-kudo u1)

;; Get user statistics
(contract-call? .community-kudos get-user-stats 'SP1234567890ABCDEF)

;; Get kudos sent by a user
(contract-call? .community-kudos get-kudos-sent-by-user 'SP1234567890ABCDEF)
```

## 📚 Contract Functions

### Public Functions

#### `send-kudo`
Sends a kudo to another user.

```clarity
(define-public (send-kudo (to principal) (message (string-ascii 100)) (category (string-ascii 30))))
```

**Parameters:**
- `to`: Recipient's principal address
- `message`: Kudo message (max 100 characters)
- `category`: Category tag (max 30 characters)

**Returns:** `(ok {id: uint, block: uint})` or error

#### `send-kudos-batch`
Sends kudos to multiple recipients in a single transaction.

```clarity
(define-public (send-kudos-batch (recipients (list 10 principal)) (message (string-ascii 100)) (category (string-ascii 30))))
```

**Parameters:**
- `recipients`: List of up to 10 recipient addresses
- `message`: Kudo message for all recipients
- `category`: Category tag for all kudos

#### `set-contract-owner`
Changes the contract owner (admin only).

```clarity
(define-public (set-contract-owner (new-owner principal)))
```

### Read-Only Functions

#### `get-kudo`
Retrieves a specific kudo by ID.

```clarity
(define-read-only (get-kudo (id uint)))
```

#### `get-user-stats`
Gets statistics for a specific user.

```clarity
(define-read-only (get-user-stats (user principal)))
```

Returns:
```clarity
{
  sent-count: uint,
  received-count: uint,
  last-activity: uint
}
```

#### `get-kudos-sent-by-user`
Gets list of kudo IDs sent by a user.

```clarity
(define-read-only (get-kudos-sent-by-user (user principal)))
```

#### `get-kudos-received-by-user`
Gets list of kudo IDs received by a user.

```clarity
(define-read-only (get-kudos-received-by-user (user principal)))
```

#### `get-kudos-by-range`
Gets kudos within a specific ID range.

```clarity
(define-read-only (get-kudos-by-range (start-id uint) (end-id uint)))
```

#### `can-send-kudo`
Checks if a user can send a kudo to another user.

```clarity
(define-read-only (can-send-kudo (sender principal) (recipient principal)))
```

#### `get-kudo-count`
Gets the total number of kudos sent.

```clarity
(define-read-only (get-kudo-count))
```

#### `get-contract-owner`
Gets the current contract owner.

```clarity
(define-read-only (get-contract-owner))
```

## ⚠️ Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| u100 | `ERR_SAME_SENDER_RECEIVER` | Cannot send kudo to yourself |
| u101 | `ERR_TOO_SOON` | Rate limit exceeded, try again later |
| u102 | `ERR_MESSAGE_TOO_LONG` | Message exceeds 100 characters |
| u103 | `ERR_CATEGORY_TOO_LONG` | Category exceeds 30 characters |
| u104 | `ERR_KUDO_NOT_FOUND` | Kudo with specified ID not found |
| u105 | `ERR_UNAUTHORIZED` | Unauthorized action |
| u106 | `ERR_INVALID_PRINCIPAL` | Invalid principal address |

## 🔧 Configuration

### Constants
```clarity
(define-constant MAX_MESSAGE_LENGTH u100)      ;; Maximum message length
(define-constant MAX_CATEGORY_LENGTH u30)      ;; Maximum category length
(define-constant MAX_KUDOS_PER_USER u100)      ;; Maximum kudos per user (future use)
```

### Rate Limiting
- **Frequency**: One kudo per block per sender-recipient pair
- **Purpose**: Prevents spam and ensures fair usage
- **Implementation**: Tracked via `last-sent` map

## 📖 Examples

### Community Recognition System
```clarity
;; Monthly recognition program
(contract-call? .community-kudos send-kudo 
  'SP1234567890ABCDEF 
  "Outstanding contribution to the community this month!" 
  "monthly-recognition")
```

### Team Collaboration
```clarity
;; Acknowledge team collaboration
(contract-call? .community-kudos send-kudo 
  'SP1234567890ABCDEF 
  "Thanks for helping me debug the smart contract!" 
  "collaboration")
```

### Event Appreciation
```clarity
;; Thank event organizers
(contract-call? .community-kudos send-kudos-batch 
  (list 'SP1111111111111111 'SP2222222222222222 'SP3333333333333333)
  "Amazing job organizing the community meetup!"
  "event-organization")
```

## 🛠️ Development

### Project Structure
```
enhanced-community-kudos/
├── contracts/
│   └── community-kudos.clar
├── tests/
│   └── community-kudos_test.ts
├── Clarinet.toml
├── README.md
└── settings/
    └── Devnet.toml
```

### Local Development
1. Start Clarinet console:
```bash
clarinet console
```

2. Deploy contract:
```clarity
::deploy_contract community-kudos
```

3. Test functions:
```clarity
::call_contract_func community-kudos send-kudo 'ST1234567890ABCDEF "Test message" "test"
```

### Gas Optimization Features
- **Efficient data structures**: Optimized map structures for fast lookups
- **Batch operations**: Reduce transaction costs with batch sending
- **Minimal storage**: Only essential data is stored on-chain
- **Smart indexing**: Efficient kudo retrieval without expensive iterations

## 🧪 Testing

### Unit Tests
Run the test suite:
```bash
clarinet test
```

### Test Coverage
- ✅ Basic kudo sending
- ✅ Rate limiting validation
- ✅ Input validation (message length, category length)
- ✅ Batch operations
- ✅ User statistics tracking
- ✅ Owner management
- ✅ Error handling

### Manual Testing Scenarios
1. **Valid kudo sending**: Test successful kudo creation
2. **Rate limiting**: Test spam prevention
3. **Input validation**: Test message/category length limits
4. **Batch operations**: Test multiple recipient sending
5. **Statistics tracking**: Verify user stats updates
6. **Owner management**: Test ownership transfer

## 🔒 Security

### Security Features
- **Input validation**: All user inputs are validated before processing
- **Rate limiting**: Prevents spam and abuse
- **Owner validation**: Comprehensive checks for ownership changes
- **Access control**: Proper authorization checks for admin functions

### Security Considerations
- **Principal validation**: Prevents null/invalid principal addresses
- **Message sanitization**: Length limits prevent storage abuse
- **Rate limiting**: Prevents spam and network congestion
- **Owner management**: Secure ownership transfer with validation

### Audit Status
- ✅ **Static analysis**: Passes Clarinet static analysis
- ✅ **Code review**: Peer reviewed for security issues
- ✅ **Best practices**: Follows Clarity security best practices

## 🤝 Contributing

We welcome contributions! Please follow these guidelines:

### Getting Started
1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature-name`
3. Make your changes
4. Add tests for new functionality
5. Run tests: `clarinet test`
6. Submit a pull request

### Development Guidelines
- Follow Clarity best practices
- Add comprehensive tests for new features
- Update documentation for API changes
- Ensure all tests pass before submitting PR
- Use clear commit messages

### Code Style
- Use descriptive variable names
- Add comments for complex logic
- Follow existing code formatting
- Use consistent error handling patterns

## 📊 Roadmap

### Version 1.0 (Current)
- ✅ Basic kudo sending
- ✅ Rate limiting
- ✅ User statistics
- ✅ Batch operations
- ✅ Owner management

### Version 1.1 (Planned)
- 🔄 Kudo reactions/likes
- 🔄 Advanced filtering options
- 🔄 Reputation scoring
- 🔄 Event emission for better indexing

### Version 2.0 (Future)
- 🔄 NFT integration for special kudos
- 🔄 Token rewards for active users
- 🔄 Advanced analytics dashboard
- 🔄 Cross-chain compatibility

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/your-username/enhanced-community-kudos/issues)
- **Discussions**: [GitHub Discussions](https://github.com/your-username/enhanced-community-kudos/discussions)
- **Documentation**: [Wiki](https://github.com/your-username/enhanced-community-kudos/wiki)

## 🙏 Acknowledgments

- **Stacks Foundation**: For the Stacks blockchain platform
- **Clarity Team**: For the Clarity smart contract language
- **Community Contributors**: For feedback and contributions

---

**Built with ❤️ for the Stacks community**