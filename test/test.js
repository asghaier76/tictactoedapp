const TicTacToe = artifacts.require("./tictactoedapp");

contract("TicTacToe", async (accounts) => {
	it("should create a new gane and test that another account can join the game", async () => {
		const instance = await TicTacToe.deployed();
        this.newGame = await instance.newGame({from:accounts[0]});
        
	});
	///////// Unit test need to be completed
});