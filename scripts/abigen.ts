import { ethers, upgrades } from 'hardhat';
import { task } from 'hardhat/config';
import * as fs from 'fs/promises';
import * as path from 'path';

task('abigen', 'Dumps abi')
  .addPositionalParam('contract')
  .setAction(async (args) => {
    try {
      // Read the input JSON file
      const jsonData = await fs.readFile(
        `/Users/Projects/Javascript/icm/contracts/eth/artifacts/contracts/${args.contract}.sol/${args.contract}.json`,
        'utf-8'
      );

      // Parse the JSON data into an object
      const jsonObject = JSON.parse(jsonData);

      // You can manipulate or log the jsonObject if necessary

      // Write the object to a new JSON file
      const output = `./abis/${args.contract}.json`;
      const outputJsonData = JSON.stringify(jsonObject.abi, null, 2); // Prettified JSON with 2-space indentation
      await fs.writeFile(output, outputJsonData, 'utf-8');

      console.log(`Successfully written to ${output}`);
    } catch (err) {
      console.error('Error reading or writing JSON file:', err);
    }
  });
