pragma solidity >=0.4.22 <0.7.0;

contract CryptoSOS 
{
    address payable internal owner;
    
    address payable internal player1;
    address payable internal player2;
    
    string[9] grid=["-","-","-","-","-","-","-","-","-"];
    
    //help variables
    address internal lastPlayed;
    
    uint internal turnsTaken;
    
    bool public gameOver;
    
    address payable internal winner;
    
    //cancel,ur2slow
    uint internal cancelTimestamp;
    uint internal ur2slowTimestamp;
    
    //events
    event PlayEvent(address,address);
    
    event MoveEvent(address,uint8,uint8);
    
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
    
    modifier basicReqToPlay()
    {
        require(msg.sender==player1 || msg.sender==player2, "Not a valid player");
        require(player1!=address(0) && player2!=address(0), "Wait for another player to join!");
        require(!gameOver, "The game has already ended!");
        require(msg.sender!=lastPlayed, "Sorry, its not your turn!");
        _;
    }
    
    function play() public payable payMeFirst
    {
        if(player1==address(0))
        {
            player1 = msg.sender;
            cancelTimestamp = block.timestamp;
            
            emit PlayEvent(player1,address(0));
        }else if(player2==address(0))
        {
            player2=msg.sender;
            emit PlayEvent(player1,player2);
        }
        //return address(this).balance;
    }
    
    function placeS(uint8 pos) public basicReqToPlay
    {
        require(pos>=0 && pos<=8 && keccak256(abi.encodePacked(grid[pos]))==keccak256(abi.encodePacked('-')), "Not a valid move!");
        
        grid[pos]='S';
        
        lastPlayed=msg.sender;
        
        turnsTaken++;
        
        ur2slowTimestamp = block.timestamp;
        
        emit MoveEvent(msg.sender,pos,1);
        
        if(isWinner())
        {
            require(address(this).balance>=1.8 ether, "Something went wrong with the payment!");
            winner=msg.sender;
            winner.transfer(1.8 ether);
            gameOver=true;
        }else if(turnsTaken==9)//in  case nobody wins
        {
            require(address(this).balance>=1.8 ether, "Something went wrong with the payment!");
            player1.transfer(0.9 ether);
            player2.transfer(0.9 ether);
            gameOver=true;
        }
    }
    
    function placeO(uint8 pos) public basicReqToPlay
    {
        require(pos>=0 && pos<=8 && keccak256(abi.encodePacked(grid[pos]))==keccak256(abi.encodePacked('-')), "Not a valid move!");
        
        grid[pos]='O';
        
        lastPlayed=msg.sender;
        
        turnsTaken++;
        
        ur2slowTimestamp = block.timestamp;
        
        emit MoveEvent(msg.sender,pos,2);
        
        if(isWinner())
        {
            require(address(this).balance>=1.8 ether,"Something went wrong with the payment!");
            winner=msg.sender;
            winner.transfer(1.8 ether);
            gameOver=true;
        }else if(turnsTaken==9)//in  case nobody wins
        {
            require(address(this).balance>=1.8 ether, "Something went wrong with the payment!");
            player1.transfer(0.9 ether);
            player2.transfer(0.9 ether);
            gameOver=true;
        }
    }
    
    function isWinner() internal view returns(bool){
        uint8[3][8] memory winningFilters = [
            [0, 1, 2], [3, 4, 5], [6, 7, 8],  // Rows
            [0, 3, 6], [1, 4, 7], [2, 5, 8],  // Cols
            [0, 4, 8], [6, 4, 2]              // Diags
        ];
          
        for (uint8 i = 0; i < winningFilters.length; i++) {
            uint8[3] memory filter = winningFilters[i];
            if (
                keccak256(abi.encodePacked(grid[filter[0]])) ==keccak256(abi.encodePacked('S')) && 
                keccak256(abi.encodePacked(grid[filter[1]])) ==keccak256(abi.encodePacked('O')) &&
                keccak256(abi.encodePacked(grid[filter[2]])) ==keccak256(abi.encodePacked('S'))
            ) {
                return true;
            }
        }
    } 
    
    function getGameState() public view returns(string memory)
    {
        return string(abi.encodePacked(grid[0],' ',grid[1],' ',grid[2],' ',grid[3],' ',grid[4],' ',grid[5],' ',grid[6],' ',grid[7],' ',grid[8]));
    }
    
    function collectProfit() public onlyOwner
    {
        require(gameOver,"You have to wait till the end of the game!");
        owner.transfer(address(this).balance);
    }
    
    function cancel() public
    {
        require(player1==msg.sender && player2==address(0),"You cant call that Function!");
        require(now>=(cancelTimestamp+2 minutes),"You have to wait 2 minutes before cancel!");
        msg.sender.transfer(1 ether);
        gameOver=true;
    }
    
    function ur2slow() public
    {
        require(player1!=address(0) && player2!=address(0),"You cant call that function!");
        require(msg.sender==lastPlayed,"Dont try to cheat!");
        require(now>=(ur2slowTimestamp+1 minutes),"You have to wait 1 minute!");
        msg.sender.transfer(1.9 ether);
        gameOver=true;
    }
    
    function balanceOfContract() public view onlyOwner returns(uint)
    {
        return address(this).balance;
    }
}