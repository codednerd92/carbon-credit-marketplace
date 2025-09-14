# Ucarbon credit marketplace

A transparent and verifiable carbon credit trading platform that connects environmental project developers with organizations seeking to offset their carbon footprint. The platform ensures credit authenticity through IoT integration, satellite monitoring, and third-party verification while providing a liquid marketplace for carbon credit trading. Features include automated retirement of credits, impact tracking, and integration with corporate sustainability reporting systems.

## Overview

This project implements a comprehensive blockchain solution using Clarity smart contracts on the Stacks blockchain.

## Smart Contracts


### carbon-credit-registry
Issues, tracks, and manages carbon credits with immutable records of their origin, verification status, and ownership throughout their lifecycle until retirement.


### verification-oracle
Integrates with external data sources and IoT devices to verify environmental project performance and automatically trigger carbon credit issuance based on verified impact.


### marketplace-exchange
Facilitates buying, selling, and retiring of carbon credits with automated matching of buyers and sellers, transparent pricing, and integration with corporate carbon accounting systems.


## Getting Started

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet)
- [Node.js](https://nodejs.org/)
- [Git](https://git-scm.com/)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/codednerd92/carbon-credit-marketplace.git
cd carbon-credit-marketplace
```

2. Install dependencies:
```bash
clarinet install
```

3. Run tests:
```bash
clarinet test
```

## Testing

Run all tests with:
```bash
clarinet test
```

## Deployment

Deploy to testnet:
```bash
clarinet deployments apply
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

This project is licensed under the MIT License.
