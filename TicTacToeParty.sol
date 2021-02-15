pragma solidity >=0.4.22 <0.7.0;

contract MultiSOS
{
    address payable public owner;
    
    uint32 public gameID;//prepei na mpei private
    
    mapping(uint32 => Game) public gamesRunning;
    
    struct Game
    {
     address payable player1;
     address payable player2;
     string[9] grid;
     address lastPlayed;
     uint  turnsTaken;
     bool  gameOver;
     address payable winner;
     uint cancelTimestamp;
     uint ur2slowTimestamp;
    }
    
    constructor() public
    {
        owner = msg.sender;
    }
    
    modifier onlyOwner()
    {
        require(owner==msg.sender, "You are not the owner of the contract!");
        _;
    }
    
    modifier payMeFirst()
    {
        require(msg.value==1 ether, "You have to pay 1 ether to play!");
        _;
    }
    
    event PlayEvent(uint32, address, address);
    
    event MoveEvent(uint32, address, uint8, uint8);
    
    function play() public payable payMeFirst
    {
        Game storage game = gamesRunning[gameID];
        
        if(game.player1==address(0)){
            game.player1=msg.sender;
            game.cancelTimestamp = block.timestamp;
            game.grid=["-","-","-","-","-","-","-","-","-"];
            emit PlayEvent(gameID, game.player1,address(0));
        }else if(game.player2==address(0)){
            game.player2=msg.sender;
            emit PlayEvent(gameID, game.player1, game.player2);
            gameID++;
        }
    }
    
    function placeS(uint32 gameid, uint8 pos) public
    {
        Game storage game = gamesRunning[gameid];
        
        require(msg.sender==game.player1 || msg.sender==game.player2, "Not a valid player");
        require(game.player1!=address(0) && game.player2!=address(0), "Wait for another player to join!");
        require(!game.gameOver, "The game has already ended!");
        require(msg.sender!=game.lastPlayed, "Sorry, its not your turn!");
        require(pos>=0 && pos<=8 && keccak256(abi.encodePacked(game.grid[pos]))==keccak256(abi.encodePacked('-')), "Not a valid move!");
        
        game.grid[pos]='S';
        
        game.lastPlayed=msg.sender;
        
        game.turnsTaken++;
        
        game.ur2slowTimestamp = block.timestamp;
        
        emit MoveEvent(gameid, msg.sender, pos, 1);
        
        if(isWinner(gameid))
        {
            require(address(this).balance>=1.8 ether, "Something went wrong with the payment!");
            game.winner=msg.sender;
            game.winner.transfer(1.8 ether);
            game.gameOver=true;
        }else if(game.turnsTaken==9)//in  case nobody wins
        {
            require(address(this).balance>=1.8 ether, "Something went wrong with the payment!");
            game.player1.transfer(0.9 ether);
            game.player2.transfer(0.9 ether);
            game.gameOver=true;
        }
    }
    
    function placeO(uint32 gameid, uint8 pos) public
    {
        Game storage game = gamesRunning[gameid];
        
        require(msg.sender==game.player1 || msg.sender==game.player2, "Not a valid player");
        require(game.player1!=address(0) && game.player2!=address(0), "Wait for another player to join!");
        require(!game.gameOver, "The game has already ended!");
        require(msg.sender!=game.lastPlayed, "Sorry, its not your turn!");
        require(pos>=0 && pos<=8 && keccak256(abi.encodePacked(game.grid[pos]))==keccak256(abi.encodePacked('-')), "Not a valid move!");
        
        game.grid[pos]='O';
        
        game.lastPlayed=msg.sender;
        
        game.turnsTaken++;
        
        game.ur2slowTimestamp = block.timestamp;
        
        emit MoveEvent(gameid, msg.sender, pos, 1);
        
        if(isWinner(gameid))
        {
            require(address(this).balance>=1.8 ether, "Something went wrong with the payment!");
            game.winner=msg.sender;
            game.winner.transfer(1.8 ether);
            game.gameOver=true;
        }else if(game.turnsTaken==9)//in  case nobody wins
        {
            require(address(this).balance>=1.8 ether, "Something went wrong with the payment!");
            game.player1.transfer(0.9 ether);
            game.player2.transfer(0.9 ether);
            game.gameOver=true;
        }
    }
    
    function isWinner(uint32 gameid) internal view returns(bool)
    {
        Game storage game = gamesRunning[gameid];
        
        uint8[3][8] memory winningFilters = [
            [0, 1, 2], [3, 4, 5], [6, 7, 8],  // Rows
            [0, 3, 6], [1, 4, 7], [2, 5, 8],  // Cols
            [0, 4, 8], [6, 4, 2]              // Diags
        ];
          
        for (uint8 i = 0; i < winningFilters.length; i++) {
            uint8[3] memory filter = winningFilters[i];
            if (
                keccak256(abi.encodePacked(game.grid[filter[0]])) ==keccak256(abi.encodePacked('S')) && 
                keccak256(abi.encodePacked(game.grid[filter[1]])) ==keccak256(abi.encodePacked('O')) &&
                keccak256(abi.encodePacked(game.grid[filter[2]])) ==keccak256(abi.encodePacked('S'))
            ) {
                return true;
            }
        }
    } 
    
    function collectProfit(uint32 gameid) public onlyOwner
    {
        Game storage game = gamesRunning[gameid];
        require(game.gameOver,"You have to wait till the end of the game!");
        owner.transfer(address(this).balance);
    }
    
    function getGameState(uint32 gameid) public view returns(string memory)
    {
        require(msg.sender==gamesRunning[gameid].player1 || msg.sender==gamesRunning[gameid].player2 || msg.sender==owner, "This is not your game grid!");
        Game memory game = gamesRunning[gameid];
        return string(abi.encodePacked(game.grid[0],' ',game.grid[1],' ',game.grid[2],' ',game.grid[3],' ',game.grid[4],' ',game.grid[5],' ',game.grid[6],' ',game.grid[7],' ',game.grid[8]));
    }
    
    function balanceOfContract() public view onlyOwner returns(uint)
    {
        return address(this).balance;
    }
    
    function cancel(uint32 gameid) public
    {
        Game storage game = gamesRunning[gameid];
        require(game.player1==msg.sender && game.player2==address(0),"You cant call that Function!");
        require(now>=(game.cancelTimestamp+2 minutes),"You have to wait 2 minutes before cancel!");
        msg.sender.transfer(1 ether);
        game.gameOver=true;
        game.player1=address(0);
    }
    
    function ur2slow(uint32 gameid) public
    {
        Game storage game = gamesRunning[gameid];
        require(game.player1!=address(0) && game.player2!=address(0),"You cant call that function!");
        require(msg.sender==game.lastPlayed,"Dont try to cheat!");
        require(now>=(game.ur2slowTimestamp+1 minutes),"You have to wait 1 minute!");
        msg.sender.transfer(1.9 ether);
        game.gameOver=true;
    }
}
