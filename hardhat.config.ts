// import { HardhatUserConfig } from "hardhat/config";
// import "@nomicfoundation/hardhat-toolbox";

// const config: HardhatUserConfig = {
//   solidity: "0.8.17",
// };

// export default config;


import '@nomiclabs/hardhat-waffle';
import '@openzeppelin/hardhat-upgrades';
import secrets from './secrets';

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html


// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    version: '0.8.9',
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    ropsten: {
      url: process.env.ROPSTEN_URL || '',
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    bsctest: {
      url: 'https://data-seed-prebsc-1-s1.binance.org:8545',
      accounts: secrets.keys.dev,
      chainId: 97,
      gasPrice: 'auto',
      gas: 'auto',
    },
    
    polygon: {
      url: secrets.rpc.polygon,
      accounts: secrets.keys.prod,
      chainId: 137,
      gas: 5100000,
      // gasPrice: 25000000000,
      timeout: 7200000,
    },
    avax: {
      url: secrets.rpc.avax,
      accounts: secrets.keys.prod,
      chainId: 43114,
      gas: 5100000,
      // gasPrice: 25000000000,
      timeout: 7200000,
    },
  },
};