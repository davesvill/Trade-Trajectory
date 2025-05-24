# PROJECT : TRADE TRAJECTORY TRANSPARENCY PLATFORM

## README.md

# Trade Trajectory Transparency Platform

A blockchain-powered supply chain tracking system that enables manufacturers to create transparent, verifiable product batches while ensuring consumer safety through immutable record-keeping on the Stacks blockchain.

## Overview

This smart contract provides a comprehensive solution for supply chain transparency, allowing manufacturers to register product batches with cryptographic verification while enabling consumers and retailers to verify product authenticity and safety status.

## Core Capabilities

- **Manufacturer Certification**: Secure registration and verification of manufacturing facilities
- **Product Category Management**: Flexible system for defining different product types and specifications
- **Batch Tracking**: Immutable registration of product batches with cryptographic hashes
- **Safety Verification**: Real-time verification of product safety and recall status
- **Recall Management**: Secure system for managing product recalls and safety alerts

## Smart Contract Interface

### Platform Management
- `update-platform-owner`: Transfer platform administrative rights
- `certify-manufacturer`: Verify and approve manufacturing facilities
- `define-product-category`: Create new product categories with specifications

### Manufacturer Operations
- `register-manufacturer`: Register as a certified manufacturer
- `create-product-batch`: Register new product batches with verification codes
- `recall-product-batch`: Issue recalls for safety or quality issues

### Verification Functions
- `get-batch-details`: Retrieve complete batch information
- `verify-product-safety`: Check product safety and recall status
- `get-manufacturer-details`: Get manufacturer certification status
- `get-category-specifications`: View product category requirements

## Error Reference

- `ERR-ACCESS-DENIED (300)`: Insufficient permissions for operation
- `ERR-MANUFACTURER-EXISTS (301)`: Manufacturer already registered
- `ERR-PRODUCT-NOT-EXISTS (302)`: Product batch or manufacturer not found
- `ERR-UNSUPPORTED-CATEGORY (303)`: Invalid product category
- `ERR-PRODUCT-RECALLED (304)`: Product has been recalled
- `ERR-BATCH-EXPIRED (305)`: Product batch has exceeded shelf life
- `ERR-INVALID-PARAMETERS (306)`: Invalid input data provided
- `ERR-ZERO-PRINCIPAL (307)`: Invalid wallet address
- `ERR-INVALID-TIME-SPAN (308)`: Invalid time duration specified
- `ERR-PRODUCT-EXISTS (309)`: Product batch already exists
- `ERR-INVALID-BATCH-CODE (310)`: Invalid cryptographic batch code

## Implementation Example

```clarity
;; Register as a manufacturer
(contract-call? .supply-chain-tracker register-manufacturer 
    "Global Foods Inc" 
    "https://globalfoods.com")

;; Create a product batch (after certification)
(contract-call? .supply-chain-tracker create-product-batch
    "BATCH-2024-001"
    'SP1234567890123456789012345678901234567890
    "organic-produce"
    0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890ab
    "Organic tomatoes harvested from Farm A, Lot 15")

;; Verify product safety
(contract-call? .supply-chain-tracker verify-product-safety
    "BATCH-2024-001"
    'SP1234567890123456789012345678901234567890)
```

## Security Architecture

- **Multi-layer Validation**: Comprehensive input validation for all data types
- **Access Control**: Role-based permissions for platform owners, manufacturers, and public users
- **Cryptographic Integrity**: SHA-256 batch codes for tamper-proof product identification
- **Immutable Records**: Blockchain-based storage ensures data integrity and transparency

## Development Setup

1. **Prerequisites**: Clarinet CLI, Stacks wallet
2. **Local Testing**: `clarinet check` and `clarinet test`
3. **Deployment**: Compatible with Stacks testnet and mainnet

## Use Cases

- **Food Safety**: Track organic produce from farm to consumer
- **Pharmaceuticals**: Verify medication authenticity and recall status
- **Electronics**: Ensure component authenticity and warranty tracking
- **Textiles**: Verify sustainable and ethical manufacturing practices
