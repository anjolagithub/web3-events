
---

# Quiktis  

## Overview  
**Quiktis** is a blockchain-based decentralized application (dApp) designed to revolutionize ticketing by ensuring transparency, security, and efficiency in the ticketing process. Built using Solidity and Foundry, this platform integrates key functionalities such as event creation, ticket sales, and escrow for secure transactions.

## Features  
- **Event Factory:** Centralized contract for creating and managing events.  
- **Event Ticketing:** Contract for issuing and managing tickets linked to specific events.  
- **Escrow System:** Ensures secure payments between buyers and sellers.  
- **Dynamic Metadata:** Tickets have customizable metadata, allowing for detailed event descriptions.  
- **Compliance:** The system enforces corporate rules and ensures standardization across all operations.  

## Project Structure  
```
├── script
│   └── DeployEventTicketing.s.sol  # Deployment script for contracts
├── src
│   ├── Base64.sol                 # Library for Base64 encoding
│   ├── EventEscrow.sol            # Contract for secure payments
│   ├── EventFactory.sol           # Contract to manage event creation
│   └── EventTicketing.sol         # Core ticketing contract
└── test
    └── EventPlatFormTest.t.sol    # Unit tests for contracts
```

## Prerequisites  
Before you begin, ensure you have the following:  
- Foundry installed on your machine. [Installation Guide](https://book.getfoundry.sh/getting-started/installation.html)  
- A Sepolia RPC URL (e.g., from Alchemy or Infura).  
- A private key with sufficient test ETH on Sepolia.  

## Installation  
1. Clone the repository:  
   ```bash
   git clone https://github.com/anjolagithub/web3-event.git
   cd event-ticketing
   ```  
2. Install dependencies:  
   ```bash
   forge install
   ```  

## Deployment  
1. Set environment variables:  
   Create a `.env` file with the following details:  
   ```env
   RPC_URL="https://your-sepolia-rpc-url"
   PRIVATE_KEY="your-private-key"
   ```  

2. Deploy contracts:  
   ```bash
   source .env
   forge script script/DeployEventTicketing.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
   ```  

## Testing  
Run the unit tests to ensure everything works as expected:  
```bash
forge test -vv
```  

## Usage  
1. Deploy the contracts using the deployment script.  
2. Use the **EventFactory** to create events.  
3. Use the **EventTicketing** contract to manage tickets for each event.  
4. Secure transactions using the **EventEscrow** contract.  

## Contributing  
We welcome contributions! Feel free to submit issues, feature requests, or pull requests to improve the platform.  

## License  
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.  

---  
