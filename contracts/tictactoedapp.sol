// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

contract tictactoedapp {
    address public owner;
    enum gameStatus { OPEN, ON, COMPLETE }
                            // represents all cells 
    uint24[9] validMoves = [0x00001, 0x00004, 0x00010, 0x00040, 0x00100, 0x00400, 0x01000, 0x04000, 0x10000];
                            // --------Rows-----------,--------Cols------------,----Diagonal----  //                              
    uint24[8] gameFinalList = [0x00015, 0x00540, 0x15000, 0x01041, 0x04104, 0x10410, 0x10101, 0x01110];
    uint256 drawMask = (0x800000000);  // used to find out if to play X or O by masking the concantenated addresses
    struct gameBoard {
        uint24 cells; // the 9 least significant bits are used to represent the board
        address winner; 
        address initiator;
        bool nextTurn; // defined whether X or O will play
        bool initiatorRule; // based on the random draw assign the initiator the role X or O
        address opponent;
    }
    
    mapping(uint256 => gameBoard) public openGamesList;
    mapping(uint256 => gameBoard) public startedGamesList;
    mapping(uint256 => gameBoard) public completedGamesList;
    constructor(
    )
    public
    {
      owner = msg.sender;
    }
     
    event gameStatusChange(uint256 indexed _gameId, gameStatus indexed _status, address indexed _initiator);
    event movesRecord(uint256 indexed _gameId, address indexed _initiator, uint24 _move);
    
    /// @dev checks if a game is complete and there is a winner.
    /// @param _gameId the game ID.
    function _checkGameCompleted(uint256 _gameId) private {
        uint24 gameCells = startedGamesList[_gameId].cells;
        for (uint8 idx = 0; idx < gameFinalList.length; idx++) {
            uint24 patternCompleted = startedGamesList[_gameId].nextTurn ? gameFinalList[idx] : gameFinalList[idx] << 1;
            uint24 mask =  startedGamesList[_gameId].nextTurn ? 0x55555 : 0xAAAAA ;
            if ( (gameCells&mask) == patternCompleted ) {
                startedGamesList[_gameId].winner = msg.sender;
                completedGamesList[_gameId] = startedGamesList[_gameId];
                delete startedGamesList[_gameId];
                emit gameStatusChange(_gameId, gameStatus.COMPLETE, msg.sender); 
                break;
            }
        }
    }
    
    /// @dev Retrieves the game cells.
    /// @param _gameId the game ID.
    /// @return the game cell type uint24
    function getCell(uint256 _gameId) public view returns (uint24 ) {
        return startedGamesList[_gameId].cells;
    }
    
    // ensure only owner can execute the transaction
    modifier onlyOwner {
        require(msg.sender == owner, "only the owner can perfrom this action");
        _;
    }
    
    // ensure that the move is valid based on the 9 defined moves
    modifier isValidMove(uint24 _move) {
        require(_checkMoveValidity(_move), "invalid move");
        _;
    }
    
    /// @dev Function to check the proposed move against the valid moves.
    /// @param _move the game ID.
    /// @return _moveisValid bool if move is valid or not
    function _checkMoveValidity(uint24 _move) private view returns (bool){
        bool _moveisValid = false;
        for (uint8 idx = 0; idx < validMoves.length; idx++) {
          if (_move == validMoves[idx]) {
            _moveisValid = true;
            break;
          }
        }
        return _moveisValid;
    }
    
    // ensure that the call can be made only towards open game
    modifier isGameOpen(uint256 _gameId) {
        require(openGamesList[_gameId].initiator != address(0), "no such open game");
        _;
    }
    
    // ensures the message sender is not the game initiator
    modifier notInitiator(uint256 _gameId) {
        require(openGamesList[_gameId].initiator != msg.sender, "you are the initiator of this game");
        _;
    }
    
    // ensures that only the message initiator can ecexute the function
    modifier onlyInitiator(uint256 _gameId) {
        require(startedGamesList[_gameId].initiator == msg.sender, "only the initiator can perform this action");
        //require(openGamesList[_gameId].initiator == address(0));
        _;
    }
    
    // ensure that the game has started
    modifier hasGameStarted(uint256 _gameId) {
        require(startedGamesList[_gameId].initiator != address(0) && startedGamesList[_gameId].opponent != address(0), "No game has started with this ID");
        _;
    }
    
    // check if cell is empty or not
    modifier isCellEmpty(uint256 _gameId, uint24 _move) {
        require(!(_checkCellValue( startedGamesList[_gameId].cells, _move) || _checkCellValue( startedGamesList[_gameId].cells, _move >> 1)), "cell is not empty");
        //require( ((startedGamesList[_gameId].cells & _move) == 0) || (startedGamesList[_gameId].nextTurn && (startedGamesList[_gameId].cells & (_move << 1) == 0) ), "cell is not empty");
        _;
    }
    
    // check if its the issuer turn
    modifier isItMyTurn(uint256 _gameId) {
        require( (startedGamesList[_gameId].initiator == msg.sender && startedGamesList[_gameId].nextTurn == startedGamesList[_gameId].initiatorRule) || (startedGamesList[_gameId].opponent == msg.sender && startedGamesList[_gameId].nextTurn != startedGamesList[_gameId].initiatorRule), "Sorry, not your turn");
        _;
    }
    
    /// @dev Function to check the indicated cell value.
    /// @param _cells the cells value.
    /// @param _pos the move index.
    /// @return bool if cell is 0 or 1
    function _checkCellValue(uint24 _cells, uint24 _pos) private pure returns (bool) {
        return ((_cells & (uint24(0x00001) << _pos)) != 0);
    }
    
    /// @dev Function restricted for initiator only and only started games to resent the game
    /// @param _gameId the game ID.
    /// @return true if successful 
    function resetBoard(uint256 _gameId) public onlyInitiator(_gameId) hasGameStarted(_gameId) returns (bool) {
        startedGamesList[_gameId].cells = 0;
        return true;
    }
    
    /// @dev Function called to set the specified cell value to 1 indicating a move made by the player
    /// @param _move the specified move by the player.
    /// @param _gameId the game ID.
    function setCell(uint24 _move, uint256 _gameId) public hasGameStarted( _gameId) isItMyTurn(_gameId) isValidMove( _move) isCellEmpty(_gameId,_move) {
        uint24 registerMove = startedGamesList[_gameId].nextTurn ? _move << 1 : _move ;
        startedGamesList[_gameId].cells = startedGamesList[_gameId].cells | registerMove;
        startedGamesList[_gameId].nextTurn = !startedGamesList[_gameId].nextTurn;
        emit movesRecord( _gameId, msg.sender, _move);
        _checkGameCompleted(_gameId);
        
    }
    
    /// @dev Function to create a new open game
    /// @return gameId, randomly generated gameId 
    function newGame() public returns (uint256) {
        uint256 gameId = uint256(keccak256(abi.encodePacked(block.timestamp))) & uint256(keccak256(abi.encodePacked(msg.sender)));
        openGamesList[gameId].cells = 0;
        openGamesList[gameId].initiator = msg.sender;
        openGamesList[gameId].nextTurn = false;
        emit gameStatusChange(gameId, gameStatus.OPEN, msg.sender);
        return gameId;
    }
    

    /// @dev Function for any other player except the game initator to join an open game
    /// @param _gameId the game ID.
    function acceptGame(uint256 _gameId) public isGameOpen(_gameId) notInitiator(_gameId) {
        startedGamesList[_gameId].cells = 0;
        startedGamesList[_gameId].opponent = msg.sender;
        startedGamesList[_gameId].initiator = openGamesList[_gameId].initiator;
        uint256 drawCoin = (uint256(keccak256(abi.encodePacked(startedGamesList[_gameId].initiator,startedGamesList[_gameId].opponent, block.number))));
        bool whostarts = (drawCoin & drawMask == 0 ) ? true : false;
        startedGamesList[_gameId].initiatorRule = whostarts;
        delete openGamesList[_gameId];
        emit gameStatusChange(_gameId, gameStatus.ON , msg.sender);
    }
    
}