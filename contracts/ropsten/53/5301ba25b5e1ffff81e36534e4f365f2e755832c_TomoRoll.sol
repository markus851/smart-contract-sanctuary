pragma solidity ^0.4.25;

contract TomoRoll{
    address public admin;
    address[] public players;
    uint8[] public luckynumbers;
    uint256 sizebet;
    uint256 win;
    uint256 _seed = now;
    event BetResult(
    address from,
    uint256 betvalue,
    uint256 prediction,
    uint8 luckynumber,
    bool win,
    uint256 wonamount
    );
    
    event LuckyDrop(
    address from,
    uint256 betvalue,
    uint256 prediction,
    uint8 luckynumber,
    string congratulation
    );
    
    event Shake(
    address from,
    bytes32 make_chaos
    );
    
    constructor() public{
        admin = 0x1E1C1Fa8Ee39151ba082daE2F24E906882F4681C;
    }
    
    function random() private view returns (uint8) {
        return uint8(uint256(keccak256(block.timestamp, block.difficulty, _seed))%100); // random 0-99
    }

    function bet(uint8 under) public payable{
        require(msg.value >= .001 ether);
        require(msg.value*98/under < address(this).balance);
        require(under > 0 && under < 96);
        sizebet = msg.value;
        win = uint256 (sizebet*98/under);
        uint8 _random = random();
        luckynumbers.push(_random);
        
        if (_random < under) {
                msg.sender.transfer(win);
                emit BetResult(msg.sender, msg.value, under, _random, true, win);
        } else {
            emit BetResult(msg.sender, msg.value, under, _random, false, 0x0);
        }
    }
    

    modifier onlyAdmin() {
        // Ensure the participant awarding the ether is the admin
        require(msg.sender == admin);
        _;
    }
    
    function withdrawEth(address to, uint256 balance) onlyAdmin {
        if (balance == uint256(0x0)) {
            to.transfer(address(this).balance);
        } else {
        to.transfer(balance);
    }
  }

    function getLuckynumber() public view returns(uint8[]) {
        // Return list of luckynumbers
        return luckynumbers;
    }
    function shake(uint256 choose_a_number_to_chaos_the_algo) public {
        _seed = uint256(keccak256(choose_a_number_to_chaos_the_algo));
        emit Shake(msg.sender, "You changed the algo");
    }
    
}