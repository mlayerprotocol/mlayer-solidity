# mLayer solidity smart contracts
* A collection of mLayer Smart Contracts for EVM based chains

* mLayer (message layer) is an open, decentralized communication network that enables the creation, transmission and termination of data of all sizes, leveraging modern protocols. mLayer is a comprehensive suite of communication protocols designed to evolve with the ever-advancing realm of cryptography. Given its protocol-centric nature, it is an adaptable and universally integrable tool conceived for the decentralized era. Visit the mLayer [documentation](https://mlayer.gitbook.io/introduction/what-is-mlayer) to learn more

# Contracts

The contracts are bupgradable, following the Open Zeppelin Proxy Upgrade Pattern. Each contract will be explained in brief detail below.

### Stake (Validator) Contract
The stake contract allows validators stake mLayer tokens on their nodes. Being a proof of stake network, Only validator nodes with an adequate amount of tokens staked is allowed to participate in the network.

### Token Contract
An ERC-20 token (GRT) that is used as a work token to power the network incentives and for DAO participation. The token is inflationary.


