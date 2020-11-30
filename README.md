# TicTacToe Solidity Project

This is a Tic Tac Toe solidity smart contract that allows players to create new games and invite other to join.

The smart contract allows for multiple games and multiple players

## Dependecies 

The smart contract is built using Truffle framework, so Truffle and Ganache need to be installed

- npm install truffle --save-dev
- npm install ganache-cli --save-dev

Also we need to install concurrently that will allow to run both Truffle and Ganache ina single command, added to the scripts section in package.json
- npm install concurrently --save-dev

## Runnig the code

First to ensure using the same mnemonic across different runs, run the command that will add the environment variable whihc is used it the script defined in package.json

- export MNEMONIC="mnemonic phrase"

Then run the below command which will perform truffle compile and migrate and use the Ganache network

- npm run start
