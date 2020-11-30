const TicTacToe = artifacts.require("./tictactoedapp");

module.exports = function(deployer) {
	deployer.deploy(TicTacToe);
}